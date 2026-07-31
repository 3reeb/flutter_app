// =============================================================================
// quantum_mock_adapters.dart
// =============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import '../quantum_api_engine.dart';
import '../quantum_auth_engine.dart';
import '../quantum_socket_engine.dart';
import '../internal/quantum_socket_stream_hub.dart';
import '../quantum_media_api.dart';
// =============================================================================
// SECTION 1: MOCK NETWORK CONFIGURATION
// =============================================================================

class MockNetworkConfig {
  final Duration minLatency;
  final Duration maxLatency;
  final double failureProbability; // 0.0 to 1.0

  const MockNetworkConfig({
    this.minLatency = const Duration(milliseconds: 10),
    this.maxLatency = const Duration(milliseconds: 50),
    this.failureProbability = 0.0,
  });

  Future<void> simulate() async {
    final rand = math.Random();

    // Simulate failure
    if (failureProbability > 0.0 && rand.nextDouble() < failureProbability) {
      throw const SocketException('Simulated network failure (Offline)');
    }

    // Simulate latency
    if (maxLatency.inMilliseconds > 0) {
      final delay = minLatency.inMilliseconds +
          (maxLatency.inMilliseconds > minLatency.inMilliseconds
              ? rand.nextInt(
                  maxLatency.inMilliseconds - minLatency.inMilliseconds + 1)
              : 0);
      await Future.delayed(Duration(milliseconds: delay));
    }
  }
}

class SocketException implements Exception {
  final String message;
  const SocketException(this.message);
  @override
  String toString() => 'SocketException: $message';
}

// =============================================================================
// SECTION 2: MOCK API DRIVER (In-Memory DB with Latency)
// =============================================================================

class MockApiDriver implements VaultDriver {
  @override
  final String driverId = 'mock_api';

  final MockNetworkConfig networkConfig;

  // In-memory representation of collections and global documents
  final Map<String, Map<String, dynamic>> _collections = {};
  final Map<String, dynamic> _globals = {};

  MockApiDriver({this.networkConfig = const MockNetworkConfig()});

  @override
  Future<void> initialize(Map<String, dynamic> config) async {}

  String _generateId() => DateTime.now().microsecondsSinceEpoch.toString();

  @override
  Future<ApiResult<dynamic>> read(String slug, Map<String, dynamic> query,
      {String? id, required DriverContext context}) async {
    try {
      await networkConfig.simulate();

      if (slug == 'error_slug') {
        return ApiResult.failure(
            const VaultStreamException('mock_err', 'Simulated 500 error'),
            driverUsed: driverId);
      }

      if (query.isEmpty && id == null && _globals.containsKey(slug)) {
        return ApiResult.success(_globals[slug], driverUsed: driverId);
      }

      _collections[slug] ??= {};

      // Handle Schema and Permissions
      if (query['op'] == 'schema') {
        return ApiResult.success({
          'schema': {'slug': slug, 'kind': query['kind'], 'fields': []}
        }, driverUsed: driverId);
      }
      if (query['op'] == 'permissions') {
        return ApiResult.success(
            {'read': true, 'create': true, 'update': true, 'delete': true},
            driverUsed: driverId);
      }

      if (query['op'] == 'count') {
        return ApiResult.success({'count': 10}, driverUsed: driverId);
      }
      if (query['op'] == 'exists') {
        return ApiResult.success({'exists': true}, driverUsed: driverId);
      }

      if (id != null) {
        if (_collections[slug]!.containsKey(id)) {
          return ApiResult.success(_collections[slug]![id],
              driverUsed: driverId);
        } else {
          return ApiResult.failure(
              const VaultStreamException('not_found', 'Document not found'),
              driverUsed: driverId);
        }
      }

      List<dynamic> results = _collections[slug]!.values.toList();

      if (query.containsKey('where')) {
        final whereClause = query['where'] as Map<String, dynamic>;
        results = results.where((doc) {
          bool match = true;
          whereClause.forEach((k, v) {
            if (v is Map && v.containsKey('equals')) {
              if (doc[k] != v['equals']) match = false;
            } else if (doc[k] != v) {
              match = false;
            }
          });
          return match;
        }).toList();
      }

      if (query.containsKey('sort')) {
        final sort = query['sort'] as Map<String, dynamic>;
        final field = sort['field'] as String?;
        final desc = sort['descending'] == true;
        if (field != null) {
          results.sort((a, b) {
            final valA = a[field] ?? '';
            final valB = b[field] ?? '';
            final cmp = valA.compareTo(valB);
            return desc ? -cmp : cmp;
          });
        }
      }

      final limit = query['limit'] as int?;
      final offset = query['offset'] as int?;
      if (offset != null && offset < results.length) {
        results = results.sublist(offset);
      } else if (offset != null) {
        results = [];
      }
      if (limit != null && results.length > limit) {
        results = results.sublist(0, limit);
      }

      return ApiResult.success({'items': results, 'total': results.length},
          driverUsed: driverId);
    } catch (e) {
      return ApiResult.failure(
          VaultStreamException('network_error', e.toString()),
          driverUsed: driverId);
    }
  }

  @override
  Future<ApiResult<dynamic>> write(
      String slug, String op, Map<String, dynamic> body,
      {String? id, required DriverContext context}) async {
    try {
      await networkConfig.simulate();

      if (op == 'upsertGlobal' || op == 'updateGlobal' || op == 'setGlobal') {
        _globals[slug] = body;
        return ApiResult.success(body, driverUsed: driverId);
      }

      _collections[slug] ??= {};

      if (op == 'createMany') {
        final items = body['items'] as List;
        for (final item in items) {
          final data = Map<String, dynamic>.from(item);
          final newId = data['id'] ?? data['_id'] ?? _generateId();
          data['id'] = newId;
          _collections[slug]![newId] = data;
        }
        return ApiResult.success({'created': items.length},
            driverUsed: driverId);
      }

      if (op == 'create') {
        final data = Map<String, dynamic>.from(body);
        final newId = data['id'] ?? data['_id'] ?? _generateId();
        data['id'] = newId;
        _collections[slug]![newId] = data;
        return ApiResult.success(data, driverUsed: driverId);
      }

      if (op == 'updateById' || op == 'patchById') {
        if (id != null && _collections[slug]!.containsKey(id)) {
          final existing = _collections[slug]![id] as Map<String, dynamic>;
          final merged = {...existing, ...body};
          _collections[slug]![id] = merged;
          return ApiResult.success(merged, driverUsed: driverId);
        } else {
          return ApiResult.failure(
              const VaultStreamException('not_found', 'Document not found'),
              driverUsed: driverId);
        }
      }

      if (op == 'upsertById') {
        final data = Map<String, dynamic>.from(body);
        final docId = id ?? _generateId();
        data['id'] = docId;
        _collections[slug]![docId] = data;
        return ApiResult.success(data, driverUsed: driverId);
      }

      if (op == 'deleteById') {
        if (id != null && _collections[slug]!.containsKey(id)) {
          final removed = _collections[slug]!.remove(id);
          return ApiResult.success(removed, driverUsed: driverId);
        } else {
          return ApiResult.success({'deleted': 0}, driverUsed: driverId);
        }
      }

      if (op == 'deleteMany') {
        _collections[slug]!.clear(); // Simplified mock behavior
        return ApiResult.success({'deleted': 1}, driverUsed: driverId);
      }

      if (op == 'updateMany') {
        // Simplified mock behavior
        return ApiResult.success({'updated': 1}, driverUsed: driverId);
      }

      return ApiResult.failure(
          VaultStreamException('unsupported_op', 'Operation $op not supported'),
          driverUsed: driverId);
    } catch (e, st) {
      print('MockApiDriver.write ERROR: $e\n$st');
      return ApiResult.failure(
          VaultStreamException('network_error', e.toString()),
          driverUsed: driverId);
    }
  }

  @override
  Stream<ApiResult<dynamic>> subscribe(String slug, Map<String, dynamic> query,
      {required DriverContext context}) async* {
    final res = await read(slug, query, context: context);
    yield res;
  }

  @override
  Future<void> dispose() async {
    _collections.clear();
    _globals.clear();
  }
}

// =============================================================================
// SECTION 3: MOCK AUTH DRIVER (Full Flow Coverage)
// =============================================================================

class MockAuthDriver implements AuthDriver {
  @override
  final String driverId = 'mock_auth';

  final MockNetworkConfig networkConfig;

  final Map<String, Map<String, dynamic>> _users = {};

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

  MockAuthDriver({this.networkConfig = const MockNetworkConfig()});

  @override
  Future<void> initialize(Map<String, dynamic> config) async {}

  String _generateToken(String userId) =>
      'mock_jwt_token_${userId}_${DateTime.now().millisecondsSinceEpoch}';

  SessionContext _buildSession(String userId, Map<String, dynamic> user) {
    return SessionContext(
      userId: userId,
      sessionId: 'session_${DateTime.now().millisecondsSinceEpoch}',
      accessToken: _generateToken(userId),
      refreshToken: 'mock_refresh_token',
      expiresAt: DateTime.now().add(const Duration(days: 7)),
      claims: user,
      authProviderUsed: 'mock',
    );
  }

  @override
  Future<AuthResult<SessionContext>> login(AuthRequest request) async {
    try {
      await networkConfig.simulate();
      final email = request.credentials['email'];
      final password = request.credentials['password'];

      if (email == 'fail@example.com') {
        return AuthResult.failure(
            const AuthException('invalid_credentials', 'Wrong password'),
            driverUsed: driverId);
      }

      String? foundUserId;
      Map<String, dynamic>? foundUser;

      for (var entry in _users.entries) {
        if (entry.value['email'] == email &&
            entry.value['password'] == password) {
          foundUserId = entry.key;
          foundUser = entry.value;
          break;
        }
      }

      if (foundUser != null && foundUserId != null) {
        return AuthResult.success(_buildSession(foundUserId, foundUser),
            driverUsed: driverId);
      } else {
        final newId = DateTime.now().microsecondsSinceEpoch.toString();
        final newUser = {
          'email': email,
          'password': password,
          'name': 'Mock User'
        };
        _users[newId] = newUser;
        return AuthResult.success(_buildSession(newId, newUser),
            driverUsed: driverId);
      }
    } catch (e) {
      return AuthResult.failure(AuthException('network_error', e.toString()),
          driverUsed: driverId);
    }
  }

  @override
  Future<AuthResult<SessionContext>> register(AuthRequest request) async {
    try {
      await networkConfig.simulate();
      final email = request.credentials['email'];
      final password = request.credentials['password'];
      final profile = request.credentials['profile'] ?? {};

      final newId = DateTime.now().microsecondsSinceEpoch.toString();
      final newUser = {
        'email': email,
        'password': password,
        ...profile as Map<String, dynamic>
      };
      _users[newId] = newUser;

      return AuthResult.success(_buildSession(newId, newUser),
          driverUsed: driverId);
    } catch (e) {
      return AuthResult.failure(AuthException('network_error', e.toString()),
          driverUsed: driverId);
    }
  }

  @override
  Future<AuthResult<SessionContext>> refreshSession(
      SessionContext currentSession) async {
    try {
      await networkConfig.simulate();
      if (currentSession.accessToken == 'expired_token') {
        return AuthResult.failure(
            const AuthException('token_expired', 'Refresh failed'),
            driverUsed: driverId);
      }
      return AuthResult.success(
          _buildSession(currentSession.userId!, currentSession.claims),
          driverUsed: driverId);
    } catch (e) {
      return AuthResult.failure(AuthException('network_error', e.toString()),
          driverUsed: driverId);
    }
  }

  @override
  Future<AuthResult<void>> logout(SessionContext session) async {
    await networkConfig.simulate();
    return const AuthResult.success(null);
  }

  @override
  Future<AuthResult<void>> revokeSession(SessionContext session) =>
      logout(session);

  @override
  Future<AuthResult<SessionContext>> updateProfile(Map<String, dynamic> profile,
      {required SessionContext currentSession}) async {
    try {
      await networkConfig.simulate();
      if (_users.containsKey(currentSession.userId)) {
        final existing = _users[currentSession.userId]!;
        final merged = {...existing, ...profile};
        _users[currentSession.userId!] = merged;
        return AuthResult.success(_buildSession(currentSession.userId!, merged),
            driverUsed: driverId);
      }
      return AuthResult.success(_buildSession(currentSession.userId!, profile),
          driverUsed: driverId);
    } catch (e) {
      return AuthResult.failure(AuthException('network_error', e.toString()),
          driverUsed: driverId);
    }
  }

  @override
  Future<AuthResult<void>> forgotPassword(String email) async {
    await networkConfig.simulate();
    return const AuthResult.success(null);
  }

  @override
  Future<AuthResult<void>> resetPassword(
      {required String token, required String password}) async {
    await networkConfig.simulate();
    return const AuthResult.success(null);
  }

  @override
  Future<AuthResult<SessionContext>> changePassword(
      {required SessionContext currentSession,
      required String oldPassword,
      required String newPassword}) async {
    await networkConfig.simulate();
    if (_users.containsKey(currentSession.userId)) {
      _users[currentSession.userId]!['password'] = newPassword;
    }
    return AuthResult.success(currentSession, driverUsed: driverId);
  }

  @override
  Future<AuthResult<AuthChallenge>> requestOtp(AuthChallenge request) async {
    await networkConfig.simulate();
    return AuthResult.success(
        AuthChallenge(
          challengeId: 'mock_otp',
          type: AuthChallengeType.otp,
          state: AuthChallengeState.pending,
          purpose: 'login',
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(minutes: 5)),
          destination: request.destination,
        ),
        driverUsed: driverId);
  }

  @override
  Future<AuthResult<SessionContext>> verifyOtp(
      AuthChallenge challenge, String code) async {
    await networkConfig.simulate();
    if (code == '000000') {
      return AuthResult.failure(
          const AuthException('invalid_code', 'Wrong OTP'),
          driverUsed: driverId);
    }
    return AuthResult.success(
        _buildSession('otp_user', {'phone': challenge.destination}),
        driverUsed: driverId);
  }

  @override
  Future<AuthResult<AuthChallenge>> beginPasskeyRegistration(
      AuthRequest request) async {
    await networkConfig.simulate();
    return AuthResult.success(
        AuthChallenge(
          challengeId: 'mock_pk',
          type: AuthChallengeType.passkeyRegistration,
          state: AuthChallengeState.pending,
          purpose: 'register',
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(minutes: 5)),
        ),
        driverUsed: 'mock_auth');
  }

  @override
  Future<AuthResult<SessionContext>> completePasskeyRegistration(
      AuthRequest request) async {
    await networkConfig.simulate();
    return AuthResult.success(_buildSession('pk_user', {'passkey': true}),
        driverUsed: driverId);
  }

  @override
  Future<AuthResult<AuthChallenge>> beginPasskeyAuthentication(
      AuthRequest request) async {
    await networkConfig.simulate();
    return AuthResult.success(
        AuthChallenge(
          challengeId: 'mock_pk_auth',
          type: AuthChallengeType.passkeyAuthentication,
          state: AuthChallengeState.pending,
          purpose: 'login',
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(minutes: 5)),
        ),
        driverUsed: 'mock_auth');
  }

  @override
  Future<AuthResult<SessionContext>> completePasskeyAuthentication(
      AuthRequest request) async {
    await networkConfig.simulate();
    return AuthResult.success(_buildSession('pk_user', {'passkey': true}),
        driverUsed: driverId);
  }

  @override
  Future<AuthResult<AuthChallenge>> beginBiometricAuth(
      AuthRequest request) async {
    await networkConfig.simulate();
    return AuthResult.success(
        AuthChallenge(
          challengeId: 'mock_bio',
          type: AuthChallengeType.biometricVerification,
          state: AuthChallengeState.pending,
          purpose: 'biometric',
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(minutes: 5)),
        ),
        driverUsed: 'mock_auth');
  }

  @override
  Future<AuthResult<SessionContext>> completeBiometricAuth(
      AuthRequest request) async {
    await networkConfig.simulate();
    return AuthResult.success(_buildSession('bio_user', {'biometric': true}),
        driverUsed: driverId);
  }

  @override
  Future<AuthResult<SessionContext>> linkProvider(
      AuthProvider provider, AuthRequest request) async {
    await networkConfig.simulate();
    return AuthResult.success(
        _buildSession('oauth_user', {'provider': provider.toString()}),
        driverUsed: driverId);
  }

  @override
  Future<AuthResult<SessionContext>> unlinkProvider(
      AuthProvider provider, AuthRequest request) async {
    await networkConfig.simulate();
    return AuthResult.success(_buildSession('oauth_user', {}),
        driverUsed: driverId);
  }

  @override
  Future<AuthResult<AuthChallenge>> confirmOperation(
      AuthRequest request) async {
    await networkConfig.simulate();
    return AuthResult.success(
        AuthChallenge(
          challengeId: 'mock_stepup',
          type: AuthChallengeType.stepUp,
          state: AuthChallengeState.pending,
          purpose: 'confirm',
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(minutes: 5)),
        ),
        driverUsed: 'mock_auth');
  }

  @override
  Future<AuthResult<List<String>>> discoverAuthMethods(
      AuthRequest request) async {
    await networkConfig.simulate();
    return const AuthResult.success(['emailPassword', 'passkey', 'google'],
        driverUsed: 'mock_auth');
  }

  @override
  Future<AuthResult<Map<String, dynamic>>> getAuthPolicy() async {
    await networkConfig.simulate();
    return const AuthResult.success({'mfa_required': false},
        driverUsed: 'mock_auth');
  }

  @override
  Future<AuthResult<void>> verifyEmail(String token) async {
    await networkConfig.simulate();
    return const AuthResult.success(null);
  }

  @override
  Future<AuthResult<void>> resendVerification() async {
    await networkConfig.simulate();
    return const AuthResult.success(null);
  }

  @override
  Future<AuthResult<void>> unlockAccount(String token) async {
    await networkConfig.simulate();
    return const AuthResult.success(null);
  }

  @override
  Future<AuthResult<void>> revokeAllSessions(
      SessionContext currentSession) async {
    await networkConfig.simulate();
    return const AuthResult.success(null);
  }

  @override
  Future<void> dispose() async {
    _users.clear();
  }
}

// =============================================================================
// SECTION 4: MOCK SOCKET DRIVER (Pub/Sub & Streaming)
// =============================================================================

class MockSocketDriver extends QLSocketDriverBase<SocketState, SocketMessage>
    implements SocketDriver {
  @override
  final String driverId = 'mock_ws';

  final MockNetworkConfig networkConfig;

  SocketState _currentState = SocketState.disconnected;

  MockSocketDriver({this.networkConfig = const MockNetworkConfig()});

  @override
  Future<void> connect(String url, Map<String, dynamic> options) async {
    try {
      _changeState(SocketState.connecting);
      await networkConfig.simulate();
      if (url.contains('fail')) {
        throw const SocketException('Connection failed');
      }
      _changeState(SocketState.connected);
    } catch (_) {
      _changeState(SocketState.error);
      rethrow;
    }
  }

  void _changeState(SocketState state) {
    _currentState = state;
    emitState(state);
  }

  @override
  Future<void> send(SocketMessage message) async {
    if (_currentState != SocketState.connected) {
      throw Exception('Socket not connected');
    }
    await networkConfig.simulate();

    if (message.headers.containsKey('eventId')) {
      Future.delayed(const Duration(milliseconds: 10), () {
        emitMessage(SocketMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          event: message.event,
          payload: {'echo': message.payload},
          channel: message.channel,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          headers: {'correlationId': message.id},
        ));
      });
    }
  }

  @override
  Future<void> sendRawBinary(Uint8List data) async {
    if (_currentState != SocketState.connected) {
      throw Exception('Socket not connected');
    }
    await networkConfig.simulate();
    Future.delayed(const Duration(milliseconds: 10), () {
      emitBinary(data);
    });
  }

  @override
  Future<void> disconnect() async {
    _changeState(SocketState.disconnected);
  }

  void simulateIncomingMessage(SocketMessage msg) {
    if (_currentState == SocketState.connected) {
      emitMessage(msg);
    }
  }
}
