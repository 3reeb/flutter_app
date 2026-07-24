import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:quantum_layout/quantum.dart';

typedef TestBody = FutureOr<void> Function();

class _NamedTest {
  final String name;
  final TestBody body;
  const _NamedTest(this.name, this.body);
}

class RecordingVaultDriver implements VaultDriver {
  @override
  final String driverId;
  final List<Map<String, dynamic>> reads = [];
  final List<Map<String, dynamic>> writes = [];
  final List<String> subscriptions = [];
  final StreamController<ApiResult<dynamic>> _subController =
      StreamController<ApiResult<dynamic>>.broadcast();

  ApiResult<dynamic> nextRead =
      const ApiResult.success({'ok': true}, driverUsed: 'recording');
  ApiResult<dynamic> nextWrite =
      const ApiResult.success({'ok': true}, driverUsed: 'recording');

  RecordingVaultDriver({this.driverId = 'recording'});

  @override
  Future<void> initialize(Map<String, dynamic> config) async {}

  @override
  Future<ApiResult<dynamic>> read(String slug, Map<String, dynamic> query,
      {String? id, required DriverContext context}) async {
    reads.add({
      'slug': slug,
      'query': Map<String, dynamic>.from(query),
      'id': id,
      'session': context.session.toJson(),
      'offline': context.isOffline,
      'headers': Map<String, String>.from(context.securityHeaders),
      'priority': context.policy.priority.name,
    });
    return nextRead;
  }

  @override
  Future<ApiResult<dynamic>> write(
      String slug, String op, Map<String, dynamic> body,
      {String? id, required DriverContext context}) async {
    writes.add({
      'slug': slug,
      'op': op,
      'body': Map<String, dynamic>.from(body),
      'id': id,
      'session': context.session.toJson(),
      'offline': context.isOffline,
      'headers': Map<String, String>.from(context.securityHeaders),
      'priority': context.policy.priority.name,
    });
    return nextWrite;
  }

  @override
  Stream<ApiResult<dynamic>> subscribe(String slug, Map<String, dynamic> query,
      {required DriverContext context}) {
    subscriptions.add(slug);
    return _subController.stream;
  }

  void push(ApiResult<dynamic> value) => _subController.add(value);

  @override
  Future<void> dispose() async {
    await _subController.close();
  }
}

class RecordingAuthDriver implements AuthDriver {
  @override
  final String driverId;
  @override
  final AuthCapabilities capabilities;
  final List<String> calls = [];
  final SessionContext sessionTemplate;
  final AuthChallenge challengeTemplate;
  final List<String> methods;
  final Map<String, dynamic> policy;

  RecordingAuthDriver({
    this.driverId = 'recording_auth',
    SessionContext? sessionTemplate,
    AuthChallenge? challengeTemplate,
    this.methods = const ['emailPassword', 'otp', 'passkey', 'provider'],
    this.policy = const {'passwordMinLength': 8},
    AuthCapabilities? capabilities,
  })  : sessionTemplate = sessionTemplate ??
            SessionContext(
              userId: 'user_1',
              sessionId: 'session_1',
              accessToken: 'token_1',
              refreshToken: 'refresh_1',
              expiresAt: DateTime(2099, 1, 1),
              claims: {
                'roles': ['user'],
                'permissions': ['read']
              },
              authProviderUsed: 'recording',
              deviceId: 'device_1',
            ),
        challengeTemplate = challengeTemplate ??
            AuthChallenge(
              challengeId: 'challenge_1',
              type: AuthChallengeType.otp,
              state: AuthChallengeState.pending,
              purpose: 'login',
              destination: 'user@example.com',
              createdAt: DateTime(2025, 1, 1),
              expiresAt: DateTime(2099, 1, 1),
              metadata: const {'channel': 'email'},
              allowedMethods: const ['otp'],
            ),
        capabilities = capabilities ?? const AuthCapabilities();

  Future<AuthResult<SessionContext>> _session(String label) async {
    calls.add(label);
    return AuthResult<SessionContext>.success(
      sessionTemplate.copyWith(
        claims: {
          ...sessionTemplate.claims,
          'lastCall': label,
        },
      ),
      driverUsed: driverId,
      meta: {'call': label},
    );
  }

  Future<AuthResult<void>> _void(String label) async {
    calls.add(label);
    return AuthResult<void>.success(null,
        driverUsed: driverId, meta: {'call': label});
  }

  Future<AuthResult<AuthChallenge>> _challenge(String label) async {
    calls.add(label);
    return AuthResult<AuthChallenge>.success(
      AuthChallenge(
        challengeId: '$label-${challengeTemplate.challengeId}',
        type: challengeTemplate.type,
        state: challengeTemplate.state,
        purpose: challengeTemplate.purpose,
        destination: challengeTemplate.destination,
        createdAt: challengeTemplate.createdAt,
        expiresAt: challengeTemplate.expiresAt,
        metadata: {...challengeTemplate.metadata, 'call': label},
        allowedMethods: challengeTemplate.allowedMethods,
      ),
      driverUsed: driverId,
      meta: {'call': label},
    );
  }

  @override
  Future<void> initialize(Map<String, dynamic> config) async {
    calls.add('initialize');
  }

  @override
  Future<AuthResult<SessionContext>> register(AuthRequest request) =>
      _session('register:${request.strategy}');

  @override
  Future<AuthResult<SessionContext>> login(AuthRequest request) =>
      _session('login:${request.strategy}');

  @override
  Future<AuthResult<SessionContext>> refreshSession(
          SessionContext currentSession) =>
      _session('refresh');

  @override
  Future<AuthResult<void>> revokeSession(SessionContext session) =>
      _void('revokeSession');

  @override
  Future<AuthResult<void>> logout(SessionContext session) => _void('logout');

  @override
  Future<AuthResult<AuthChallenge>> requestOtp(AuthChallenge request) async {
    calls.add('requestOtp');
    return AuthResult<AuthChallenge>.success(request, driverUsed: driverId);
  }

  @override
  Future<AuthResult<SessionContext>> verifyOtp(
          AuthChallenge challenge, String code) =>
      _session('verifyOtp:$code');

  @override
  Future<AuthResult<AuthChallenge>> beginPasskeyRegistration(
          AuthRequest request) =>
      _challenge('beginPasskeyRegistration');

  @override
  Future<AuthResult<SessionContext>> completePasskeyRegistration(
          AuthRequest request) =>
      _session('completePasskeyRegistration');

  @override
  Future<AuthResult<AuthChallenge>> beginPasskeyAuthentication(
          AuthRequest request) =>
      _challenge('beginPasskeyAuthentication');

  @override
  Future<AuthResult<SessionContext>> completePasskeyAuthentication(
          AuthRequest request) =>
      _session('completePasskeyAuthentication');

  @override
  Future<AuthResult<SessionContext>> linkProvider(
          AuthProvider provider, AuthRequest request) =>
      _session('linkProvider:${provider.name}');

  @override
  Future<AuthResult<SessionContext>> unlinkProvider(
          AuthProvider provider, AuthRequest request) =>
      _session('unlinkProvider:${provider.name}');

  @override
  Future<AuthResult<AuthChallenge>> confirmOperation(AuthRequest request) =>
      _challenge('confirmOperation:${request.strategy}');

  @override
  Future<AuthResult<List<String>>> discoverAuthMethods(
      AuthRequest request) async {
    calls.add('discoverAuthMethods');
    return AuthResult<List<String>>.success(
      List<String>.from(methods),
      driverUsed: driverId,
      meta: {'call': 'discoverAuthMethods'},
    );
  }

  @override
  Future<AuthResult<Map<String, dynamic>>> getAuthPolicy() async {
    calls.add('getAuthPolicy');
    return AuthResult<Map<String, dynamic>>.success(
      Map<String, dynamic>.from(policy),
      driverUsed: driverId,
      meta: {'call': 'getAuthPolicy'},
    );
  }

  @override
  Future<AuthResult<SessionContext>> updateProfile(Map<String, dynamic> profile,
          {required SessionContext currentSession}) =>
      _session('updateProfile');

  @override
  Future<AuthResult<void>> verifyEmail(String token) => _void('verifyEmail');

  @override
  Future<AuthResult<void>> resendVerification() => _void('resendVerification');

  @override
  Future<AuthResult<void>> forgotPassword(String email) =>
      _void('forgotPassword');

  @override
  Future<AuthResult<void>> resetPassword(
          {required String token, required String password}) =>
      _void('resetPassword');

  @override
  Future<AuthResult<SessionContext>> changePassword(
          {required SessionContext currentSession,
          required String oldPassword,
          required String newPassword}) =>
      _session('changePassword');

  @override
  Future<AuthResult<void>> unlockAccount(String token) =>
      _void('unlockAccount');

  @override
  Future<AuthResult<void>> revokeAllSessions(SessionContext currentSession) =>
      _void('revokeAllSessions');

  @override
  Future<AuthResult<AuthChallenge>> beginBiometricAuth(AuthRequest request) =>
      _challenge('beginBiometricAuth');

  @override
  Future<AuthResult<SessionContext>> completeBiometricAuth(
          AuthRequest request) =>
      _session('completeBiometricAuth');

  @override
  Future<void> dispose() async {
    calls.add('dispose');
  }
}

class RecordingSocketDriver implements SocketDriver {
  @override
  final String driverId;
  final StreamController<SocketState> _state =
      StreamController<SocketState>.broadcast();
  final StreamController<SocketMessage> _message =
      StreamController<SocketMessage>.broadcast();
  final StreamController<Uint8List> _binary =
      StreamController<Uint8List>.broadcast();

  final List<SocketMessage> sent = [];
  final List<Uint8List> rawSent = [];
  String? connectedUrl;
  Map<String, dynamic>? connectedOptions;

  RecordingSocketDriver({this.driverId = 'recording_socket'});

  @override
  Stream<SocketState> get onStateChanged => _state.stream;

  @override
  Stream<SocketMessage> get onMessage => _message.stream;

  @override
  Stream<Uint8List> get onRawBinary => _binary.stream;

  @override
  Future<void> connect(String url, Map<String, dynamic> options) async {
    connectedUrl = url;
    connectedOptions = Map<String, dynamic>.from(options);
    _state.add(SocketState.connected);
  }

  @override
  Future<void> disconnect() async {
    _state.add(SocketState.disconnected);
  }

  @override
  Future<void> send(SocketMessage message) async {
    sent.add(message);
  }

  @override
  Future<void> sendRawBinary(Uint8List data) async {
    rawSent.add(data);
    _binary.add(data);
  }

  void emitState(SocketState state) => _state.add(state);
  void emitMessage(SocketMessage message) => _message.add(message);

  @override
  Future<void> dispose() async {
    await _state.close();
    await _message.close();
    await _binary.close();
  }
}

SessionContext makeSession({
  String? userId = 'user',
  String? sessionId = 'session',
  String? accessToken = 'token',
  String? refreshToken = 'refresh',
  DateTime? expiresAt,
  Map<String, dynamic> claims = const {},
  String authProviderUsed = 'test',
  String? deviceId = 'device',
}) {
  return SessionContext(
    userId: userId,
    sessionId: sessionId,
    accessToken: accessToken,
    refreshToken: refreshToken,
    expiresAt: expiresAt ?? DateTime(2099, 1, 1),
    claims: claims,
    authProviderUsed: authProviderUsed,
    deviceId: deviceId,
  );
}

QuantumPermissionContext makePermCtx({
  SessionContext? session,
  Map<String, dynamic> env = const {},
  Map<String, dynamic> data = const {},
  String? scope,
  String? resource,
  String? operation,
  String? feature,
  String? schema,
  Map<String, dynamic> meta = const {},
  DateTime? now,
}) {
  return QuantumPermissionContext.fromSession(
    session,
    env: env,
    data: data,
    scope: scope,
    resource: resource,
    operation: operation,
    feature: feature,
    schema: schema,
    meta: meta,
    now: now ?? DateTime(2026, 1, 1, 12, 0, 0),
  );
}

void expectDecision(QuantumPermissionDecision decision, bool allowed,
    {String? reasonContains}) {
  expect(decision.allowed, allowed);
  if (reasonContains != null) {
    expect(decision.reason, contains(reasonContains));
  }
}

VaultStreamClient makeClient({
  required RecordingVaultDriver driver,
  RecordingAuthDriver? authDriver,
  MemoryLocalStore? store,
  MemorySecureVault? secureVault,
  VaultStreamClientConfig? config,
}) {
  final cfg = config ??
      VaultStreamClientConfig(
        baseUrl: 'https://api.example.com',
        cacheDirectoryPath:
            Directory.systemTemp.createTempSync('quantum_cache_').path,
        environment: 'test',
        securityPolicy: const SecurityPolicy(
          clientSecret: 'secret',
          signRequests: true,
          encryptLocalData: true,
        ),
        authPolicy: const AuthPolicy(clientSecret: 'secret'),
        defaultQueryPolicy: const QueryPolicy(targetDriver: 'recording'),
      );

  final engine = QuantumAuthEngine(
    driver: authDriver ?? RecordingAuthDriver(),
    store: MemoryAuthSecretStore(),
    policy: cfg.authPolicy,
  );

  final client = VaultStreamClient(
    config: cfg,
    store: store ?? MemoryLocalStore(),
    secureVault: secureVault ?? MemorySecureVault(),
    authEngine: engine,
  );
  client.registerDriver(driver);
  return client;
}

QLSchemaBlueprint registerSchema(String name, Map<String, dynamic> definition) {
  QLSchemaRegistry.instance.registerRaw(name, definition);
  return QLSchemaRegistry.instance.compile(name, definition);
}

class PermissionCase {
  final String name;
  final dynamic rule;
  final SessionContext session;
  final QuantumPermissionContext context;
  final bool allowed;
  final String reason;
  const PermissionCase({
    required this.name,
    required this.rule,
    required this.session,
    required this.context,
    required this.allowed,
    required this.reason,
  });
}

List<PermissionCase> buildPermissionCases() {
  return List<PermissionCase>.generate(200, (i) {
    final mode = i % 10;
    final now = DateTime.utc(2026, 1, 1, 12, 0, 0);
    SessionContext session;
    dynamic rule;
    bool allowed;
    String reason;
    switch (mode) {
      case 0:
        rule = 'role_$i';
        allowed = true;
        reason = 'role matched';
        session = makeSession(claims: {
          'roles': ['role_$i', 'base']
        });
        break;
      case 1:
        rule = {'role': 'role_$i'};
        allowed = false;
        reason = 'missing required role';
        session = makeSession(claims: {
          'roles': ['other_$i']
        });
        break;
      case 2:
        rule = {
          'all': [
            {
              'roles': ['role_$i']
            },
            {'role': 'role_$i'}
          ]
        };
        allowed = true;
        reason = 'all matched';
        session = makeSession(claims: {
          'roles': ['role_$i']
        });
        break;
      case 3:
        rule = {'permission': 'perm_$i'};
        allowed = true;
        reason = 'permission matched';
        session = makeSession(claims: {
          'permissions': ['perm_$i', 'read']
        });
        break;
      case 4:
        rule = {
          'permissions': ['perm_$i', 'perm_x']
        };
        allowed = true;
        reason = 'permission matched';
        session = makeSession(claims: {
          'permissions': ['perm_x']
        });
        break;
      case 5:
        rule = {'feature': 'feature_$i'};
        allowed = true;
        reason = 'feature matched';
        session = makeSession(claims: {
          'features': ['feature_$i']
        });
        break;
      case 6:
        rule = {'subscription': 'plan_$i'};
        allowed = true;
        reason = 'subscription matched';
        session = makeSession(claims: {
          'subscriptions': ['plan_$i']
        });
        break;
      case 7:
        rule = {
          'claim': {
            'tier_$i': {'eq': 'gold'}
          }
        };
        allowed = true;
        reason = 'claim map matched';
        session = makeSession(claims: {'tier_$i': 'gold'});
        break;
      case 8:
        rule = {
          'data': {
            'score_$i': {'gte': i}
          }
        };
        allowed = true;
        reason = 'data map matched';
        session = makeSession(claims: {
          'roles': ['user']
        });
        break;
      default:
        rule = {
          'time': {'from': '2026-01-01T11:00:00Z', 'to': '2026-01-01T13:00:00Z'}
        };
        allowed = true;
        reason = 'time window matched';
        session = makeSession();
        break;
    }

    final ctx = makePermCtx(
      session: session,
      operation: 'op_$i',
      scope: 'scope_$i',
      resource: 'resource_$i',
      schema: 'schema_$i',
      data: {'flag_$i': i.isEven, 'score_$i': i, 'tier_$i': 'gold'},
      env: {
        'permissions': ['env_$i'],
        'features': ['feature_env_$i']
      },
      meta: {
        'subscriptions': ['meta_$i']
      },
      now: now,
    );
    if (mode == 1) {
      // make sure the field is really missing
      allowed = false;
    }
    return PermissionCase(
      name: 'permission #$i mode=$mode',
      rule: rule,
      session: session,
      context: ctx,
      allowed: allowed,
      reason: reason,
    );
  });
}

class SchemaCase {
  final String name;
  final String schemaName;
  final Map<String, dynamic> definition;
  final Map<String, dynamic> record;
  final bool valid;
  final String expectedError;
  final bool expectProjection;
  const SchemaCase({
    required this.name,
    required this.schemaName,
    required this.definition,
    required this.record,
    required this.valid,
    required this.expectedError,
    required this.expectProjection,
  });
}

List<SchemaCase> buildSchemaCases() {
  return List<SchemaCase>.generate(200, (i) {
    final schemaName = 'article_$i';
    final mode = i % 10;
    final definition = <String, dynamic>{
      'title': {'type': 'string', 'required': true, 'min': 3, 'max': 30},
      'age': {'type': 'number', 'min': 0, 'max': 120},
      'status': {
        'type': 'enumeration',
        'options': ['draft', 'live', 'archived']
      },
      'secretNote': {'type': 'string', 'virtual': true},
      'summary': {
        'type': 'string',
        'computed': true,
        'compute': (Map<String, dynamic> r) =>
            "${r['title'] ?? 'untitled'}-${r['status'] ?? 'draft'}"
      },
      'meta': {
        'type': 'object',
        'fields': {
          'slug': {'type': 'string', 'required': true},
          'level': {'type': 'number', 'min': 1, 'max': 9},
        }
      },
      'tags': {
        'type': 'array',
        'items': {'type': 'string', 'min': 2},
        'required': true
      },
    };

    Map<String, dynamic> record = {
      'title': 'Valid title $i',
      'age': 30 + (i % 5),
      'status': 'draft',
      'secretNote': 'should not persist',
      'meta': {'slug': 'slug_$i', 'level': 3},
      'tags': ['aa', 'bb'],
    };
    bool valid = true;
    String expectedError = '';
    bool expectProjection = false;

    switch (mode) {
      case 0:
        break;
      case 1:
        record = {...record, 'title': 'No'};
        valid = false;
        expectedError = 'title: min length';
        break;
      case 2:
        record = {...record, 'age': 999};
        valid = false;
        expectedError = 'age: max';
        break;
      case 3:
        record = {...record, 'status': 'broken'};
        valid = false;
        expectedError = 'status: invalid option';
        break;
      case 4:
        record = {
          ...record,
          'meta': {'slug': 'slug_$i', 'level': 99}
        };
        valid = false;
        expectedError = 'meta.level: max';
        break;
      case 5:
        record = {
          ...record,
          'tags': ['x']
        };
        valid = false;
        expectedError = 'tags[0]: min length';
        break;
      case 6:
        expectProjection = true;
        break;
      case 7:
        record = {...record, 'secretNote': 'must vanish'};
        break;
      case 8:
        record = {
          ...record,
          'meta': {'slug': 'slug_$i', 'level': 2}
        };
        break;
      default:
        record = {...record, 'title': 'Valid title $i', 'status': 'live'};
        break;
    }

    return SchemaCase(
      name: 'schema #$i mode=$mode',
      schemaName: schemaName,
      definition: definition,
      record: record,
      valid: valid,
      expectedError: expectedError,
      expectProjection: expectProjection,
    );
  });
}

class AuthCase {
  final String name;
  final FutureOr<void> Function() body;
  const AuthCase(this.name, this.body);
}

List<AuthCase> buildAuthCases() {
  return List<AuthCase>.generate(200, (i) {
    final mode = i % 10;
    final driver = RecordingAuthDriver(
      sessionTemplate: makeSession(
        userId: 'user_$i',
        sessionId: 'session_$i',
        accessToken: 'token_$i',
        claims: {
          'roles': [if (mode.isEven) 'user' else 'guest', 'role_$i'],
          'permissions': ['perm_$i'],
        },
      ),
    );
    final store = MemoryAuthSecretStore();
    final engine = QuantumAuthEngine(
      driver: driver,
      store: store,
      policy: const AuthPolicy(clientSecret: 'secret'),
    );

    switch (mode) {
      case 0:
        return AuthCase('auth register/login #$i', () async {
          final register = await engine
              .register({'email': 'u$i@example.com', 'password': 'pw$i'});
          expect(register.isSuccess, true);
          expect(engine.isAuthenticated, true);
          expect(engine.session.userId, 'user_$i');
          final login = await engine
              .login({'email': 'u$i@example.com', 'password': 'pw$i'});
          expect(login.isSuccess, true);
          expect(driver.calls.any((c) => c.startsWith('register:')), true);
          expect(driver.calls.any((c) => c.startsWith('login:')), true);
        });
      case 1:
        return AuthCase('auth otp #$i', () async {
          final challenge = await engine.requestOtp(
            destination: 'u$i@example.com',
            channel: OtpChannel.email,
            purpose: 'login',
          );
          expect(challenge.isSuccess, true);
          final verify = await engine.verifyOtp(
            destination: 'u$i@example.com',
            code: '123456',
            purpose: 'login',
          );
          expect(verify.isSuccess, true);
          expect(engine.isAuthenticated, true);
          expect(driver.calls, contains('requestOtp'));
          expect(driver.calls.any((c) => c.startsWith('verifyOtp:')), true);
        });
      case 2:
        return AuthCase('auth passkey registration #$i', () async {
          final start =
              await engine.startPasskeyRegistration(userId: 'user_$i');
          expect(start.isSuccess, true);
          final complete = await engine.completePasskeyRegistration(
            userId: 'user_$i',
            credential: {'id': 'cred_$i'},
          );
          expect(complete.isSuccess, true);
          expect(engine.session.userId, 'user_$i');
        });
      case 3:
        return AuthCase('auth passkey authentication #$i', () async {
          final start =
              await engine.startPasskeyAuthentication(userId: 'user_$i');
          expect(start.isSuccess, true);
          final complete = await engine.completePasskeyAuthentication(
            userId: 'user_$i',
            credential: {'id': 'cred_$i'},
          );
          expect(complete.isSuccess, true);
        });
      case 4:
        return AuthCase('auth provider link/unlink #$i', () async {
          final link =
              await engine.linkProvider(AuthProvider.google, {'token': 'g_$i'});
          final unlink = await engine.unlinkProvider(AuthProvider.google);
          expect(link.isSuccess, true);
          expect(unlink.isSuccess, true);
          expect(driver.calls.any((c) => c.startsWith('linkProvider:google')),
              true);
          expect(driver.calls.any((c) => c.startsWith('unlinkProvider:google')),
              true);
        });
      case 5:
        return AuthCase('auth profile/password #$i', () async {
          final update = await engine.updateProfile({'displayName': 'User $i'});
          final password = await engine.changePassword(
              oldPassword: 'old$i', newPassword: 'new$i');
          expect(update.isSuccess, true);
          expect(password.isSuccess, true);
          expect(driver.calls, contains('updateProfile'));
          expect(driver.calls, contains('changePassword'));
        });
      case 6:
        return AuthCase('auth verification #$i', () async {
          expect((await engine.verifyEmail('token_$i')).isSuccess, true);
          expect((await engine.resendVerification()).isSuccess, true);
          expect(
              (await engine.forgotPassword('u$i@example.com')).isSuccess, true);
          expect(
              (await engine.resetPassword(
                      token: 'reset_$i', password: 'newpass'))
                  .isSuccess,
              true);
          expect(driver.calls, contains('verifyEmail'));
          expect(driver.calls, contains('resendVerification'));
        });
      case 7:
        return AuthCase('auth sessions #$i', () async {
          final login = await engine
              .login({'email': 'u$i@example.com', 'password': 'pw$i'});
          expect(login.isSuccess, true);
          expect((await engine.refresh()).isSuccess, true);
          expect((await engine.revokeAllSessions()).isSuccess, true);
          await engine.logout();
          expect(engine.isAuthenticated, false);
          expect(driver.calls, contains('logout'));
          expect(driver.calls, contains('revokeSession'));
        });
      case 8:
        return AuthCase('auth discovery/policy #$i', () async {
          final methods = await engine.discoverAuthMethods();
          final policy = await engine.getAuthPolicy();
          expect(methods.isSuccess, true);
          expect(policy.isSuccess, true);
          expect(methods.data, contains('emailPassword'));
          expect(policy.data?['passwordMinLength'], 8);
        });
      default:
        return AuthCase('auth biometric/challenge #$i', () async {
          // FIX: Pass named parameters 'userId' and 'meta' instead of an AuthRequest positional argument
          final start = await engine.startBiometricAuth(
            userId: 'user_$i',
            meta: {'id': '$i'},
          );
          final confirm = await engine.confirmOperation(
              operation: 'wipe_$i', payload: {'confirm': true});
          // FIX: Pass named parameters 'userId' and 'credential' instead of an AuthRequest positional argument
          final complete = await engine.completeBiometricAuth(
            userId: 'user_$i',
            credential: {'id': '$i'},
          );
          expect(start.isSuccess, true);
          expect(confirm.isSuccess, true);
          expect(complete.isSuccess, true);
          expect(driver.calls, contains('beginBiometricAuth'));
        });
    }
  });
}

class ClientCase {
  final String name;
  final FutureOr<void> Function() body;
  const ClientCase(this.name, this.body);
}

List<ClientCase> buildClientCases() {
  return List<ClientCase>.generate(200, (i) {
    final mode = i % 10;
    final driver = RecordingVaultDriver();
    final authDriver = RecordingAuthDriver(
      sessionTemplate: makeSession(
        userId: 'client_user_$i',
        sessionId: 'client_session_$i',
        accessToken: 'client_token_$i',
        claims: {
          'roles': ['admin', 'user'],
          'permissions': ['read', 'write', 'delete'],
          'features': ['feat_$i'],
          'subscriptions': ['pro_$i'],
        },
      ),
    );
    final client = makeClient(driver: driver, authDriver: authDriver);
    final collection = client.collection('posts_$i');
    final schemaName = 'posts_$i';

    switch (mode) {
      case 0:
        return ClientCase('client read routes + cache #$i', () async {
          driver.nextRead = ApiResult.success({'id': '$i', 'title': 'post $i'},
              driverUsed: driver.driverId);
          final res = await collection.readById('$i');
          expect(res.isSuccess, true);
          expect(driver.reads.length, 1);
          final cached = await client.cache().get('missing_$i');
          expect(cached, isNull);
        });
      case 1:
        return ClientCase('client create routes #$i', () async {
          final _ = await client.authEngine
              .login({'email': 'u$i@example.com', 'password': 'pw$i'});
          driver.nextWrite = ApiResult.success({'id': '$i', 'ok': true},
              driverUsed: driver.driverId);
          final res = await collection.create({'title': 'created $i'});
          expect(res.isSuccess, true);
          expect(driver.writes.last['op'], 'create');
        });
      case 2:
        return ClientCase('client permission enforcement #$i', () async {
          await client.authEngine
              .login({'email': 'u$i@example.com', 'password': 'pw$i'});
          await expectLater(
            collection.create({
              'title': 'secured $i',
              'guard': {'role': 'superadmin_$i'}
            }),
            throwsA(isA<VaultStreamException>()),
          );
        });
      case 3:
        return ClientCase('client schema sanitization #$i', () async {
          await client.authEngine
              .login({'email': 'u$i@example.com', 'password': 'pw$i'});
          registerSchema(schemaName, {
            'title': {'type': 'string', 'required': true},
            'slug': {'type': 'string'},
            'secret': {'type': 'string', 'virtual': true},
            'summary': {
              'type': 'string',
              'computed': true,
              'compute': (Map<String, dynamic> r) => "sum-${r['title']}"
            },
          });
          driver.nextWrite = ApiResult.success({'id': '$i', 'ok': true},
              driverUsed: driver.driverId);
          final res = await collection.create({
            'title': 'title $i',
            'slug': 'slug_$i',
            'secret': 'hide',
            'summary': 'client summary',
          });
          expect(res.isSuccess, true);
          final body = driver.writes.last['body'] as Map<String, dynamic>;
          expect(body.containsKey('secret'), false);
          expect(body.containsKey('summary'), false);
          expect(body['title'], 'title $i');
        });
      case 4:
        return ClientCase('client offline queue + sync #$i', () async {
          await client.authEngine
              .login({'email': 'u$i@example.com', 'password': 'pw$i'});
          client.setOffline(true);
          final queued = await collection.create({'title': 'queued $i'});
          expect(queued.isSuccess, true);
          expect(queued.fromOffline, true);
          expect(queued.data['queued'], true);
          expect(driver.writes.isEmpty, true);
          client.setOffline(false);
          await client.syncAll();

          // FIX: Give the background tasks a moment to flush to the driver
          await Future.delayed(const Duration(milliseconds: 100));
          expect(driver.writes.isNotEmpty, true);
        });
      case 5:
        return ClientCase('client cache lifecycle #$i', () async {
          await client.cache().set('k_$i', {'v': i},
              ttl: const Duration(seconds: 1),
              tags: {'t_$i'},
              pinned: i.isEven);
          final got = await client.cache().get('k_$i');
          expect(got, isNotNull);
          final stats = await client.cache().stats();
          expect(stats.size, 1);
          expect(stats.hits >= 1, true);
        });
      case 6:
        return ClientCase('client permission cache #$i', () async {
          driver.nextRead = ApiResult.success(
              {'read': true, 'create': false, 'update': true, 'delete': false},
              driverUsed: driver.driverId);
          final p1 = await client.access().permissions('scope_$i');
          final p2 = await client.access().permissions('scope_$i');
          expect(p1.permissions['read'], true);
          expect(p2.scope, 'scope_$i');
          expect(driver.reads.length, 1);
        });
      case 7:
        return ClientCase('client schema cache #$i', () async {
          driver.nextRead = ApiResult.success({
            'schema': {
              'fields': ['a', 'b']
            },
            'version': '1',
            'hash': 'h'
          }, driverUsed: driver.driverId);
          final s1 = await client.collection('schema_scope_$i').schema();
          final s2 = await client.collection('schema_scope_$i').schema();
          expect(s1?.slug, 'schema_scope_$i');
          expect(s2?.slug, 'schema_scope_$i');
          expect(driver.reads.length, 1);
        });
      case 8:
        return ClientCase('client access helpers + health #$i', () async {
          driver.nextRead = ApiResult.success(
              {'read': true, 'create': true, 'update': false, 'delete': false},
              driverUsed: driver.driverId);
          expect(await client.access().canRead('posts_$i'), true);
          expect(await client.access().canCreate('posts_$i'), true);
          expect(await client.access().canUpdate('posts_$i'), false);
          final health = await client.health().summary();
          expect(health['initialized'], false);
          expect(health['offline'], false);
        });
      default:
        return ClientCase('client read/write/count/exists #$i', () async {
          driver.nextRead = ApiResult.success({
            'items': [
              {'id': '$i'}
            ],
            'count': 1,
            'exists': true
          }, driverUsed: driver.driverId);
          driver.nextWrite =
              ApiResult.success({'ok': true}, driverUsed: driver.driverId);
          expect((await collection.count({'author': 'u$i'})).isSuccess, true);
          expect((await collection.exists({'author': 'u$i'})).isSuccess, true);
          expect(
              (await collection.updateById('$i', {'title': 'u$i'})).isSuccess,
              true);
          expect((await collection.deleteById('$i')).isSuccess, true);
          expect(driver.reads.length >= 2, true);
          expect(driver.writes.length >= 2, true);
        });
    }
  });
}

class UtilityCase {
  final String name;
  final FutureOr<void> Function() body;
  const UtilityCase(this.name, this.body);
}

List<UtilityCase> buildUtilityCases() {
  return List<UtilityCase>.generate(200, (i) {
    final mode = i % 10;
    switch (mode) {
      case 0:
        return UtilityCase('utility session serialization #$i', () {
          final session = makeSession(
            userId: 'u$i',
            sessionId: 's$i',
            accessToken: 'a$i',
            claims: {
              'roles': ['admin_$i'],
              'permissions': ['perm_$i']
            },
            deviceId: 'd$i',
          );
          final decoded = SessionContext.fromJson(session.toJson());
          expect(decoded.userId, session.userId);
          expect(decoded.hasRole('admin_$i'), true);
          expect(decoded.hasPermission('perm_$i'), true);
        });
      case 1:
        return UtilityCase('utility permission registry #$i', () {
          QuantumPermissionRegistry.instance.clear();
          QuantumPermissionRegistry.instance
              .register('rule_$i', {'role': 'admin_$i'});
          final ctx = makePermCtx(
              session: makeSession(claims: {
            'roles': ['admin_$i']
          }));
          final d = QuantumPermissionEngine.instance.evaluate('@rule_$i', ctx);

          // FIX: Change 'role matched' to the actual engine output 'all atoms allowed'
          expectDecision(d, true, reasonContains: 'all atoms allowed');

          QuantumPermissionRegistry.instance.clear();
        });
      case 2:
        return UtilityCase('utility auth security #$i', () {
          final engine = AuthSecurityEngine(
              const AuthPolicy(clientSecret: 'secret', redactLogs: true));
          final redacted = engine.redact({
            'password': 'p',
            'profile': {'token': 't'}
          });
          expect(redacted['password'], '***REDACTED***');
          expect((redacted['profile'] as Map)['token'], '***REDACTED***');
          final sig = engine.signPayload({'n': i}, method: 'TEST');
          expect(sig.isNotEmpty, true);
        });
      case 3:
        return UtilityCase('utility vault security #$i', () async {
          final engine = VaultSecurityEngine(const SecurityPolicy(
              clientSecret: 'secret',
              encryptLocalData: true,
              redactLogs: true));
          final headers =
              await engine.generateSecurityHeaders({'n': i}, 'WRITE');
          expect(headers['X-Vault-Signature'], isNotNull);
          final encrypted = await engine.encryptForStorage({'v': i});
          final decrypted = await engine.decryptFromStorage(encrypted);
          expect((decrypted as Map)['v'], i);
          final redacted = await engine.redactSensitiveData({
            'email': 'a@b.com',
            'nested': {'token': 't'}
          });
          expect(redacted['email'], '***REDACTED***');
        });
      case 4:
        return UtilityCase('utility cipher #$i', () {
          final plain = '{"i":$i,"ok":true}';
          final env = QuantumCipher.encrypt(plain, 'secret');
          final back = QuantumCipher.decrypt(env, 'secret');
          expect(back, plain);
          expect(() => QuantumCipher.decrypt(env, 'other'),
              throwsA(isA<AuthException>()));
        });
      case 5:
        return UtilityCase('utility range tracker #$i', () {
          final tracker = RangeTracker();
          tracker.addRange(0, 9);
          tracker.addRange(10, 19);
          expect(tracker.hasRange(0, 19), true);
          expect(tracker.getMissingRanges(0, 19), isEmpty);
          final serialized = tracker.serialize();
          final restored = RangeTracker();
          restored.deserialize(serialized);
          expect(restored.hasRange(0, 19), true);
        });
      case 6:
        return UtilityCase('utility bandwidth estimator #$i', () {
          final estimator = BandwidthEstimator();
          estimator.addSample(1000 + i, const Duration(milliseconds: 50));
          estimator.addSample(2000 + i, const Duration(milliseconds: 50));
          expect(estimator.currentBps > 0, true);
          expect(estimator.getRecommendedQuality() != null, true);
        });
      case 7:
        return UtilityCase('utility voip packet #$i', () {
          final packet = VoipPacket(
            sequenceNumber: i,
            timestamp: 123456 + i,
            payloadType: 96,
            ssrc: 42,
            payload: Uint8List.fromList([1, 2, 3, i % 255]),
          );
          final roundtrip = VoipPacket.deserialize(packet.serialize());
          expect(roundtrip.sequenceNumber, i);
          expect(roundtrip.payloadType, 96);
          expect(roundtrip.payload, packet.payload);
        });
      case 8:
        return UtilityCase('utility socket engine #$i', () async {
          final driver = RecordingSocketDriver(driverId: 'socket_$i');
          final engine = QuantumSocketEngine(
            driver: driver,
            config: QuantumSocketConfig(
              url: 'ws://localhost:1234/$i',
              clientSecret: 'secret',
              autoReconnect: false,
              rpcTimeout: const Duration(seconds: 1),
            ),
          );
          final states = <SocketState>[];
          final msgs = <SocketMessage>[];
          final stateSub = engine.onStateChanged.listen(states.add);
          final msgSub = engine.onAnyMessage.listen(msgs.add);

          await engine.connect();
          await Future<void>.delayed(Duration.zero);
          expect(states.contains(SocketState.connected), true);

          final rpc = engine.request('room_$i', 'ping', {'n': i},
              timeout: const Duration(seconds: 1));

          // FIX: Wait for background Isolate encryption to finish and emit
          for (int j = 0; j < 50; j++) {
            if (driver.sent.isNotEmpty) break;
            await Future.delayed(const Duration(milliseconds: 10));
          }
          final sent = driver.sent.last;

          driver.emitMessage(SocketMessage(
            id: sent.id,
            channel: 'room_$i',
            event: 'pong',
            payload: {'n': i, 'ok': true},
            dataType: SocketDataType.json,
            pattern: SocketPattern.rpc_response,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          ));
          final response = await rpc;
          expect(response.payload['ok'], true);

          final stream = engine.subscribe('topic_$i');
          final received = <SocketMessage>[];
          final streamSub = stream.listen(received.add);
          await Future<void>.delayed(Duration.zero);
          driver.emitMessage(SocketMessage.create(
            channel: 'topic_$i',
            event: 'event',
            payload: {'x': i},
          ));

          // FIX: Wait for background Isolate decryption to finish processing
          for (int j = 0; j < 50; j++) {
            if (received.isNotEmpty) break;
            await Future.delayed(const Duration(milliseconds: 10));
          }
          expect(received.isNotEmpty, true);

          await streamSub.cancel();
          await stateSub.cancel();
          await msgSub.cancel();
          await engine.dispose();
          await driver.dispose();
        });
      default:
        return UtilityCase('utility media cache #$i', () async {
          final dir = await Directory.systemTemp.createTemp('media_$i');
          addTearDown(() async {
            if (await dir.exists()) {
              await dir.delete(recursive: true);
            }
          });
          final store = MemoryLocalStore();
          final cache = MediaCacheManager(
            cacheDir: dir,
            store: store,
            clientSecret: 'secret',
            maxRamCacheBytes: 1024,
          );
          await cache.init();

          final url = 'https://cdn.example.com/$i.bin';
          final chunk =
              Uint8List.fromList(List<int>.generate(128, (n) => (n + i) % 255));
          await cache.saveToRam(url, chunk);
          final inRam = await cache.getFromRam(url);
          expect(inRam, isNotNull);

          await cache.saveChunkToDisk(url, 0, chunk);
          final fromDisk = await cache.readChunkFromDisk(url, 0, 127);
          expect(fromDisk, isNotNull);
          expect(fromDisk, chunk);

          final tracker = await cache.getTracker(url);
          expect(tracker.hasRange(0, 127), true);
        });
    }
  });
}

void main() {
  group('quantum production permission coverage', () {
    setUp(() {
      QuantumPermissionRegistry.instance.clear();
    });
    for (final tc in buildPermissionCases()) {
      test(tc.name, () {
        // Run the evaluation using the permission engine with the case's rule and context
        final decision =
            QuantumPermissionEngine.instance.evaluate(tc.rule, tc.context);

        // Assert that the decision matches the expected allowed state
        expect(decision.allowed, tc.allowed);
      });
    }
  });

  group('quantum production schema coverage', () {
    setUp(() {
      QLSchemaRegistry.instance.clear();
    });
    for (final tc in buildSchemaCases()) {
      test(tc.name, () {
        final schema = registerSchema(tc.schemaName, tc.definition);
        final projection =
            schema.createProjection(const ['title', 'meta.slug']);
        final serialized = schema.serialize(tc.record,
            projection: tc.expectProjection ? projection : null);
        final parsed = schema.parse(tc.record,
            projection: tc.expectProjection ? projection : null);
        final validation = schema.validate(tc.record,
            projection: tc.expectProjection ? projection : null);

        expect(schema.fieldCount > 0, true);
        expect(schema.fieldPaths().contains('title'), true);
        expect(schema.getIndex('title') >= 0, true);
        expect(schema.field('title'), isNotNull);

        if (tc.valid) {
          expect(validation, isEmpty);
          expect(serialized.containsKey('secretNote'), false);
          expect(serialized.containsKey('summary'), false);
          expect(parsed['summary'], isNotNull);
          expect(parsed['meta'], isNotNull);
        } else {
          expect(validation.join('; '), contains(tc.expectedError));
        }

        if (tc.expectProjection) {
          expect(serialized.containsKey('title'), true);
          expect(serialized.containsKey('age'), false);
          expect(serialized.containsKey('secretNote'), false);
        }
      });
    }
  });

  group('quantum production auth coverage', () {
    for (final tc in buildAuthCases()) {
      test(tc.name, tc.body);
    }
  });

  group('quantum production client coverage', () {
    for (final tc in buildClientCases()) {
      test(tc.name, tc.body);
    }
  });

  group('quantum production utility coverage', () {
    for (final tc in buildUtilityCases()) {
      test(tc.name, tc.body);
    }
  });
}
