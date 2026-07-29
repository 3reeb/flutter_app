// =============================================================================
// quantum_supabase_adapters.dart
// Complete Supabase Integration: Auth, Data, Media, Realtime
// =============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:crypto/crypto.dart';

// Import your engines
import '../quantum_api_engine.dart';
import '../quantum_auth_engine.dart';
import '../quantum_media_api.dart';
import '../quantum_socket_engine.dart';
import '../internal/quantum_socket_stream_hub.dart';

// =============================================================================
// CONFIGURATION
// =============================================================================

class SupabaseConfig {
  final String projectUrl;
  final String anonKey;
  final String serviceKey;
  final String bucketName;
  final Duration connectionTimeout;
  final bool enableRealtimeSync;

  const SupabaseConfig({
    required this.projectUrl,
    required this.anonKey,
    required this.serviceKey,
    this.bucketName = 'public',
    this.connectionTimeout = const Duration(seconds: 30),
    this.enableRealtimeSync = true,
  });

  String get restUrl => '$projectUrl/rest/v1';
  String get storageUrl => '$projectUrl/storage/v1';
  String get realtimeUrl {
    final wsUrl = projectUrl.replaceAll('https://', 'wss://').replaceAll('http://', 'ws://');
    return '$wsUrl/realtime/v1';
  }
}

// =============================================================================
// 1. SUPABASE AUTHENTICATION DRIVER
// =============================================================================

class SupabaseAuthDriver implements AuthDriver {
  @override
  final String driverId = 'supabase_auth';

  @override
  final AuthCapabilities capabilities = const AuthCapabilities(
    register: true,
    login: true,
    otp: true,
    passkey: false,
    providerLogin: true,
    providerLinking: true,
    refresh: true,
    revoke: true,
    profileUpdates: true,
    passwordOperations: true,
    emailVerification: true,
    accountUnlock: true,
    discovery: true,
  );

  final SupabaseConfig config;
  final HttpClient _client;

  SupabaseAuthDriver({required this.config})
      : _client = HttpClient() {
    _client.connectionTimeout = config.connectionTimeout;
  }

  @override
  Future<void> initialize(Map<String, dynamic> cfg) async {
    // Supabase is initialized with config, no additional setup needed
  }

  Future<Map<String, dynamic>> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('${config.restUrl}$endpoint');
      final request = _client.openUrl(method, uri) as HttpClientRequest;

      // Set default headers
      request.headers.set('apikey', config.anonKey);
      request.headers.set('Content-Type', 'application/json');
      request.headers.contentType =
          ContentType('application', 'json', charset: 'utf-8');

      // Add custom headers
      headers?.forEach((k, v) => request.headers.set(k, v));

      // Add body if present
      if (body != null) {
        request.write(jsonEncode(body));
      }

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (responseBody.isEmpty) return {};
      return jsonDecode(responseBody) as Map<String, dynamic>;
    } catch (e) {
      throw AuthException('request_error', e.toString());
    }
  }

  SessionContext _parseAuthResponse(Map<String, dynamic> response) {
    final user = response['user'] as Map<String, dynamic>?;
    final session = response['session'] as Map<String, dynamic>?;

    if (user == null || session == null) {
      throw const AuthException('parse_error', 'Invalid auth response');
    }

    return SessionContext(
      userId: user['id'] as String?,
      sessionId: session['access_token'] as String?,
      accessToken: session['access_token'] as String?,
      refreshToken: session['refresh_token'] as String?,
      expiresAt: session['expires_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(session['expires_at'] as int)
          : null,
      claims: {
        'email': user['email'],
        'phone': user['phone'],
        'confirmed_at': user['confirmed_at'],
        'email_confirmed_at': user['email_confirmed_at'],
        'phone_confirmed_at': user['phone_confirmed_at'],
        'user_metadata': user['user_metadata'] ?? {},
        'app_metadata': user['app_metadata'] ?? {},
      },
      authProviderUsed: 'supabase',
    );
  }

  @override
  Future<AuthResult<SessionContext>> register(AuthRequest request) async {
    try {
      final email = request.credentials['email']?.toString();
      final password = request.credentials['password']?.toString();

      if (email == null || password == null) {
        throw const AuthException('invalid', 'Email/Password required');
      }

      final response = await _makeRequest('POST', '/auth/v1/signup', body: {
        'email': email,
        'password': password,
        'data': request.credentials['userData'] ?? {},
      });

      final session = _parseAuthResponse(response);
      return AuthResult.success(session, driverUsed: driverId);
    } catch (e) {
      return AuthResult.failure(
        e is AuthException ? e : AuthException('register_error', e.toString()),
        driverUsed: driverId,
      );
    }
  }

  @override
  Future<AuthResult<SessionContext>> login(AuthRequest request) async {
    try {
      final email = request.credentials['email']?.toString();
      final password = request.credentials['password']?.toString();

      if (email == null || password == null) {
        throw const AuthException('invalid', 'Email/Password required');
      }

      final response = await _makeRequest('POST', '/auth/v1/token', 
        body: {
          'email': email,
          'password': password,
          'grant_type': 'password',
        },
        headers: {'Content-Type': 'application/json'},
      );

      final session = _parseAuthResponse(response);
      return AuthResult.success(session, driverUsed: driverId);
    } catch (e) {
      return AuthResult.failure(
        e is AuthException ? e : AuthException('login_error', e.toString()),
        driverUsed: driverId,
      );
    }
  }

  @override
  Future<AuthResult<SessionContext>> refresh(SessionContext current) async {
    try {
      if (current.refreshToken == null) {
        throw const AuthException('invalid', 'No refresh token');
      }

      final response = await _makeRequest('POST', '/auth/v1/token',
        body: {
          'refresh_token': current.refreshToken,
          'grant_type': 'refresh_token',
        },
      );

      final session = _parseAuthResponse(response);
      return AuthResult.success(session, driverUsed: driverId);
    } catch (e) {
      return AuthResult.failure(
        e is AuthException ? e : AuthException('refresh_error', e.toString()),
        driverUsed: driverId,
      );
    }
  }

  @override
  Future<AuthResult<void>> logout(SessionContext current) async {
    try {
      final response = await _makeRequest(
        'POST',
        '/auth/v1/logout',
        headers: {
          'Authorization': 'Bearer ${current.accessToken}',
        },
      );
      return const AuthResult.success(null, driverUsed: 'supabase_auth');
    } catch (e) {
      return AuthResult.failure(
        e is AuthException ? e : AuthException('logout_error', e.toString()),
        driverUsed: driverId,
      );
    }
  }

  @override
  Future<AuthResult<SessionContext>> requestOtp(OtpRequest request) async {
    try {
      final response = await _makeRequest('POST', '/auth/v1/otp', body: {
        'phone': request.phoneNumber,
      });
      return AuthResult.success(const SessionContext(), driverUsed: driverId);
    } catch (e) {
      return AuthResult.failure(
        e is AuthException ? e : AuthException('otp_error', e.toString()),
        driverUsed: driverId,
      );
    }
  }

  @override
  Future<AuthResult<SessionContext>> verifyOtp(OtpVerification verification) async {
    try {
      final response = await _makeRequest('POST', '/auth/v1/verify', body: {
        'phone': verification.identifier,
        'token': verification.code,
        'type': 'sms',
      });
      final session = _parseAuthResponse(response);
      return AuthResult.success(session, driverUsed: driverId);
    } catch (e) {
      return AuthResult.failure(
        e is AuthException ? e : AuthException('verify_error', e.toString()),
        driverUsed: driverId,
      );
    }
  }
}

// =============================================================================
// 2. SUPABASE DATA (VAULT) DRIVER
// =============================================================================

class SupabaseVaultDriver implements VaultDriver {
  @override
  final String driverId = 'supabase_vault';

  final SupabaseConfig config;
  final HttpClient _client;

  SupabaseVaultDriver({required this.config})
      : _client = HttpClient() {
    _client.connectionTimeout = config.connectionTimeout;
  }

  @override
  Future<void> initialize(Map<String, dynamic> cfg) async {}

  Future<List<dynamic>> _executeQuery(
    String table,
    String method,
    DriverContext context, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    String? select,
  }) async {
    try {
      final queryBuilder = <String>[];

      if (select != null) {
        queryBuilder.add('select=$select');
      }

      queryParams?.forEach((k, v) {
        queryBuilder.add('$k=$v');
      });

      final query = queryBuilder.isNotEmpty ? '?${queryBuilder.join('&')}' : '';
      final uri = Uri.parse('${config.restUrl}/$table$query');
      final request = _client.openUrl(method, uri) as HttpClientRequest;

      request.headers.set('apikey', config.anonKey);
      request.headers.set('Content-Type', 'application/json');

      if (context.session.accessToken != null) {
        request.headers.set(
          'Authorization',
          'Bearer ${context.session.accessToken}',
        );
      }

      if (body != null) {
        request.write(jsonEncode(body));
      }

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (responseBody.isEmpty) return [];
      final decoded = jsonDecode(responseBody);
      return decoded is List ? decoded : [decoded];
    } catch (e) {
      throw VaultStreamException('query_error', e.toString());
    }
  }

  @override
  Future<ApiResult<List<dynamic>>> query(
    String table,
    QueryFilter filter,
    DriverContext context,
    QueryPolicy policy,
  ) async {
    try {
      final params = <String, String>{};

      // Apply filters
      if (filter.where.isNotEmpty) {
        filter.where.forEach((key, value) {
          params['$key=eq.$value'] = '';
        });
      }

      if (filter.limit != null) {
        params['limit'] = filter.limit.toString();
      }

      if (filter.offset != null) {
        params['offset'] = filter.offset.toString();
      }

      final data = await _executeQuery(
        table,
        'GET',
        context,
        select: filter.select?.join(',') ?? '*',
        queryParams: params,
      );

      return ApiResult.success(data, driverUsed: driverId);
    } catch (e) {
      return ApiResult.failure(
        e is VaultStreamException
            ? e
            : VaultStreamException('query_error', e.toString()),
        driverUsed: driverId,
      );
    }
  }

  @override
  Future<ApiResult<Map<String, dynamic>>> insert(
    String table,
    Map<String, dynamic> data,
    DriverContext context,
  ) async {
    try {
      final result = await _executeQuery(
        table,
        'POST',
        context,
        body: data,
      );
      return ApiResult.success(
        result.isNotEmpty ? result.first as Map<String, dynamic> : {},
        driverUsed: driverId,
      );
    } catch (e) {
      return ApiResult.failure(
        e is VaultStreamException
            ? e
            : VaultStreamException('insert_error', e.toString()),
        driverUsed: driverId,
      );
    }
  }

  @override
  Future<ApiResult<Map<String, dynamic>>> update(
    String table,
    String id,
    Map<String, dynamic> data,
    DriverContext context,
  ) async {
    try {
      final uri = Uri.parse('${config.restUrl}/$table?id=eq.$id');
      final request = _client.openUrl('PATCH', uri) as HttpClientRequest;

      request.headers.set('apikey', config.anonKey);
      request.headers.set('Content-Type', 'application/json');
      request.headers.set(
        'Authorization',
        'Bearer ${context.session.accessToken}',
      );

      request.write(jsonEncode(data));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (responseBody.isEmpty) return ApiResult.success({}, driverUsed: driverId);
      final decoded = jsonDecode(responseBody);
      final result =
          decoded is List && decoded.isNotEmpty ? decoded.first : decoded;

      return ApiResult.success(
        result as Map<String, dynamic>,
        driverUsed: driverId,
      );
    } catch (e) {
      return ApiResult.failure(
        e is VaultStreamException
            ? e
            : VaultStreamException('update_error', e.toString()),
        driverUsed: driverId,
      );
    }
  }

  @override
  Future<ApiResult<void>> delete(
    String table,
    String id,
    DriverContext context,
  ) async {
    try {
      final uri = Uri.parse('${config.restUrl}/$table?id=eq.$id');
      final request = _client.openUrl('DELETE', uri) as HttpClientRequest;

      request.headers.set('apikey', config.anonKey);
      request.headers.set(
        'Authorization',
        'Bearer ${context.session.accessToken}',
      );

      final response = await request.close();
      await response.transform(utf8.decoder).join();

      return const ApiResult.success(null, driverUsed: 'supabase_vault');
    } catch (e) {
      return ApiResult.failure(
        e is VaultStreamException
            ? e
            : VaultStreamException('delete_error', e.toString()),
        driverUsed: 'supabase_vault',
      );
    }
  }
}

// =============================================================================
// 3. SUPABASE STORAGE (MEDIA) DRIVER
// =============================================================================

class SupabaseStorageDriver implements MediaDriver {
  @override
  final String driverId = 'supabase_storage';

  final SupabaseConfig config;
  final HttpClient _client;

  SupabaseStorageDriver({required this.config})
      : _client = HttpClient() {
    _client.connectionTimeout = config.connectionTimeout;
  }

  @override
  Future<void> initialize(Map<String, dynamic> cfg) async {}

  @override
  Future<MediaUploadResult> upload(
    String path,
    Uint8List data,
    DriverContext context, {
    String? contentType,
    Map<String, String>? metadata,
  }) async {
    try {
      final filePath = '$path/${DateTime.now().millisecondsSinceEpoch}.bin';
      final uri = Uri.parse(
        '${config.storageUrl}/object/${config.bucketName}/$filePath',
      );

      final request = _client.openUrl('POST', uri) as HttpClientRequest;
      request.headers.set('apikey', config.anonKey);
      request.headers.set(
        'Authorization',
        'Bearer ${context.session.accessToken}',
      );

      if (contentType != null) {
        request.headers.set('Content-Type', contentType);
      }

      request.add(data);
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        throw MediaException('upload_failed', responseBody);
      }

      return MediaUploadResult(
        path: filePath,
        url: '${config.storageUrl}/object/public/${config.bucketName}/$filePath',
        size: data.length,
        mimeType: contentType ?? 'application/octet-stream',
        driverUsed: driverId,
      );
    } catch (e) {
      throw MediaException('upload_error', e.toString());
    }
  }

  @override
  Future<Uint8List> download(
    String path,
    DriverContext context,
  ) async {
    try {
      final uri = Uri.parse(
        '${config.storageUrl}/object/${config.bucketName}/$path',
      );

      final request = _client.openUrl('GET', uri) as HttpClientRequest;
      request.headers.set('apikey', config.anonKey);
      request.headers.set(
        'Authorization',
        'Bearer ${context.session.accessToken}',
      );

      final response = await request.close();
      return await response.expand((event) => event).toList() as Uint8List;
    } catch (e) {
      throw MediaException('download_error', e.toString());
    }
  }

  @override
  Future<void> delete(
    String path,
    DriverContext context,
  ) async {
    try {
      final uri = Uri.parse(
        '${config.storageUrl}/object/${config.bucketName}/$path',
      );

      final request = _client.openUrl('DELETE', uri) as HttpClientRequest;
      request.headers.set('apikey', config.anonKey);
      request.headers.set(
        'Authorization',
        'Bearer ${context.session.accessToken}',
      );

      final response = await request.close();
      if (response.statusCode != 204 && response.statusCode != 200) {
        throw MediaException('delete_failed', 'HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw MediaException('delete_error', e.toString());
    }
  }
}

// =============================================================================
// 4. SUPABASE REALTIME (SOCKET) DRIVER
// =============================================================================

class SupabaseRealtimeDriver implements SocketDriver {
  @override
  final String driverId = 'supabase_realtime';

  final SupabaseConfig config;
  late WebSocket _socket;
  final SocketStreamHub _hub = SocketStreamHub();

  SupabaseRealtimeDriver({required this.config});

  @override
  Future<void> initialize(Map<String, dynamic> cfg) async {
    if (!config.enableRealtimeSync) return;
    await _connect();
  }

  Future<void> _connect() async {
    try {
      _socket = await WebSocket.connect(config.realtimeUrl);
      _socket.listen(
        (dynamic message) {
          if (message is String) {
            final data = jsonDecode(message) as Map<String, dynamic>;
            _hub.emit('message', SocketMessage(
              id: data['id']?.toString() ?? '',
              type: data['type']?.toString() ?? '',
              channel: data['topic']?.toString() ?? '',
              payload: data['payload'] ?? {},
              timestamp: DateTime.now(),
            ));
          }
        },
        onError: (error) {
          _hub.emit('error', SocketMessage(
            id: 'error',
            type: 'error',
            channel: 'system',
            payload: {'error': error.toString()},
            timestamp: DateTime.now(),
          ));
        },
        onDone: () {
          _hub.emit('close', SocketMessage(
            id: 'close',
            type: 'close',
            channel: 'system',
            payload: {},
            timestamp: DateTime.now(),
          ));
        },
      );
    } catch (e) {
      throw SocketException('connection_failed', e.toString());
    }
  }

  @override
  Future<void> subscribe(
    String channel,
    SocketFilter filter,
    DriverContext context,
  ) async {
    try {
      final payload = {
        'topic': 'realtime:$channel',
        'event': 'subscribe',
        'payload': {
          'filter': _encodeFilter(filter),
        },
      };
      _socket.add(jsonEncode(payload));
    } catch (e) {
      throw SocketException('subscribe_error', e.toString());
    }
  }

  String _encodeFilter(SocketFilter filter) {
    final parts = <String>[];
    filter.where.forEach((key, value) {
      parts.add('$key=eq.$value');
    });
    return parts.join(',');
  }

  @override
  Future<void> unsubscribe(String channel) async {
    try {
      final payload = {
        'topic': 'realtime:$channel',
        'event': 'unsubscribe',
      };
      _socket.add(jsonEncode(payload));
    } catch (e) {
      throw SocketException('unsubscribe_error', e.toString());
    }
  }

  @override
  Stream<SocketMessage> messages(String channel) {
    return _hub.stream(channel);
  }

  @override
  Future<void> send(SocketMessage message, DriverContext context) async {
    try {
      _socket.add(jsonEncode({
        'topic': 'realtime:${message.channel}',
        'event': message.type,
        'payload': message.payload,
      }));
    } catch (e) {
      throw SocketException('send_error', e.toString());
    }
  }

  @override
  Future<void> close() async {
    try {
      await _socket.close();
    } catch (e) {
      throw SocketException('close_error', e.toString());
    }
  }
}

// =============================================================================
// HELPER EXTENSIONS
// =============================================================================

extension SupabaseDriverExtension on SupabaseConfig {
  SupabaseAuthDriver createAuthDriver() => SupabaseAuthDriver(config: this);
  SupabaseVaultDriver createVaultDriver() => SupabaseVaultDriver(config: this);
  SupabaseStorageDriver createStorageDriver() =>
      SupabaseStorageDriver(config: this);
  SupabaseRealtimeDriver createRealtimeDriver() =>
      SupabaseRealtimeDriver(config: this);
}
