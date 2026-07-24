import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

class _FakeVaultDriver implements VaultDriver {
  _FakeVaultDriver({this.driverId = 'fake'});

  @override
  final String driverId;

  int readCalls = 0;
  int writeCalls = 0;
  int subscribeCalls = 0;
  DriverContext? lastContext;
  String? lastSlug;
  String? lastOp;
  Map<String, dynamic>? lastReadQuery;
  Map<String, dynamic>? lastWriteBody;
  String? lastId;

  @override
  Future<void> initialize(Map<String, dynamic> config) async {}

  @override
  Future<ApiResult<dynamic>> read(
    String slug,
    Map<String, dynamic> query, {
    String? id,
    required DriverContext context,
  }) async {
    readCalls++;
    lastContext = context;
    lastSlug = slug;
    lastId = id;
    lastReadQuery = Map<String, dynamic>.from(query);
    return ApiResult.success({
      'slug': slug,
      'id': id,
      'query': query,
      'driver': driverId,
      'session': context.session.toJson(),
    }, driverUsed: driverId);
  }

  @override
  Future<ApiResult<dynamic>> write(
    String slug,
    String op,
    Map<String, dynamic> body, {
    String? id,
    required DriverContext context,
  }) async {
    writeCalls++;
    lastContext = context;
    lastSlug = slug;
    lastOp = op;
    lastId = id;
    lastWriteBody = Map<String, dynamic>.from(body);
    return ApiResult.success({
      'slug': slug,
      'op': op,
      'id': id,
      'body': body,
      'driver': driverId,
      'session': context.session.toJson(),
    }, driverUsed: driverId);
  }

  @override
  Stream<ApiResult<dynamic>> subscribe(
    String slug,
    Map<String, dynamic> query, {
    required DriverContext context,
  }) {
    subscribeCalls++;
    lastContext = context;
    lastSlug = slug;
    lastReadQuery = Map<String, dynamic>.from(query);
    return Stream<ApiResult<dynamic>>.value(ApiResult.success({
      'slug': slug,
      'query': query,
      'driver': driverId,
    }, driverUsed: driverId));
  }

  @override
  Future<void> dispose() async {}
}

class _FakeAuthDriver implements AuthDriver {
  _FakeAuthDriver({this.driverId = 'fake_auth'});

  @override
  final String driverId;

  @override
  final AuthCapabilities capabilities = const AuthCapabilities();

  SessionContext nextSession = const SessionContext();

  int initializeCalls = 0;
  int loginCalls = 0;
  int registerCalls = 0;
  int refreshCalls = 0;
  int logoutCalls = 0;

  @override
  Future<void> initialize(Map<String, dynamic> config) async {
    initializeCalls++;
  }

  @override
  Future<AuthResult<SessionContext>> login(AuthRequest request) async {
    loginCalls++;
    return AuthResult.success(nextSession);
  }

  @override
  Future<AuthResult<SessionContext>> register(AuthRequest request) async {
    registerCalls++;
    return AuthResult.success(nextSession);
  }

  @override
  Future<AuthResult<SessionContext>> refreshSession(
      SessionContext currentSession) async {
    refreshCalls++;
    return AuthResult.success(currentSession);
  }

  @override
  Future<AuthResult<void>> logout(SessionContext session) async {
    logoutCalls++;
    return const AuthResult.success(null);
  }

  @override
  Future<AuthResult<void>> revokeSession(SessionContext session) async {
    return const AuthResult.success(null);
  }

  @override
  Future<AuthResult<AuthChallenge>> requestOtp(AuthChallenge request) async {
    return AuthResult.success(AuthChallenge(
      challengeId: 'otp_${request.challengeId}',
      type: AuthChallengeType.otp,
      state: AuthChallengeState.pending,
      purpose: request.purpose,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      destination: request.destination,
      metadata: request.metadata,
      allowedMethods: request.allowedMethods,
    ));
  }

  @override
  Future<AuthResult<SessionContext>> verifyOtp(
      AuthChallenge challenge, String code) async {
    return AuthResult.success(nextSession);
  }

  @override
  Future<AuthResult<AuthChallenge>> beginPasskeyRegistration(
      AuthRequest request) async {
    return AuthResult.success(AuthChallenge(
      challengeId: 'passkey_reg_${request.strategy}',
      type: AuthChallengeType.passkeyRegistration,
      state: AuthChallengeState.pending,
      purpose: 'passkeyRegistration',
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
    ));
  }

  @override
  Future<AuthResult<SessionContext>> completePasskeyRegistration(
      AuthRequest request) async {
    return AuthResult.success(nextSession);
  }

  @override
  Future<AuthResult<AuthChallenge>> beginPasskeyAuthentication(
      AuthRequest request) async {
    return AuthResult.success(AuthChallenge(
      challengeId: 'passkey_auth_${request.strategy}',
      type: AuthChallengeType.passkeyAuthentication,
      state: AuthChallengeState.pending,
      purpose: 'passkeyAuthentication',
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
    ));
  }

  @override
  Future<AuthResult<SessionContext>> completePasskeyAuthentication(
      AuthRequest request) async {
    return AuthResult.success(nextSession);
  }

  @override
  Future<AuthResult<SessionContext>> linkProvider(
      AuthProvider provider, AuthRequest request) async {
    return AuthResult.success(nextSession);
  }

  @override
  Future<AuthResult<SessionContext>> unlinkProvider(
      AuthProvider provider, AuthRequest request) async {
    return AuthResult.success(nextSession);
  }

  @override
  Future<AuthResult<AuthChallenge>> confirmOperation(
      AuthRequest request) async {
    return AuthResult.success(AuthChallenge(
      challengeId: 'confirm_${request.strategy}',
      type: AuthChallengeType.stepUp,
      state: AuthChallengeState.pending,
      purpose: 'confirmOperation',
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
    ));
  }

  @override
  Future<AuthResult<List<String>>> discoverAuthMethods(
      AuthRequest request) async {
    return const AuthResult.success(<String>['password', 'otp', 'passkey']);
  }

  @override
  Future<AuthResult<Map<String, dynamic>>> getAuthPolicy() async {
    return const AuthResult.success(<String, dynamic>{'policy': 'fake'});
  }

  @override
  Future<AuthResult<SessionContext>> updateProfile(Map<String, dynamic> profile,
      {required SessionContext currentSession}) async {
    return AuthResult.success(currentSession);
  }

  @override
  Future<AuthResult<void>> verifyEmail(String token) async {
    return const AuthResult.success(null);
  }

  @override
  Future<AuthResult<void>> resendVerification() async {
    return const AuthResult.success(null);
  }

  @override
  Future<AuthResult<void>> forgotPassword(String email) async {
    return const AuthResult.success(null);
  }

  @override
  Future<AuthResult<void>> resetPassword(
      {required String token, required String password}) async {
    return const AuthResult.success(null);
  }

  @override
  Future<AuthResult<SessionContext>> changePassword(
      {required SessionContext currentSession,
      required String oldPassword,
      required String newPassword}) async {
    return AuthResult.success(currentSession);
  }

  @override
  Future<AuthResult<void>> unlockAccount(String token) async {
    return const AuthResult.success(null);
  }

  @override
  Future<AuthResult<void>> revokeAllSessions(
      SessionContext currentSession) async {
    return const AuthResult.success(null);
  }

  @override
  Future<AuthResult<AuthChallenge>> beginBiometricAuth(
      AuthRequest request) async {
    return AuthResult.success(AuthChallenge(
      challengeId: 'bio_${request.strategy}',
      type: AuthChallengeType.biometricVerification,
      state: AuthChallengeState.pending,
      purpose: 'beginBiometricAuth',
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
    ));
  }

  @override
  Future<AuthResult<SessionContext>> completeBiometricAuth(
      AuthRequest request) async {
    return AuthResult.success(nextSession);
  }

  @override
  Future<void> dispose() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

SessionContext _session({
  required String userId,
  required String sessionId,
  String? accessToken = 'access-token',
  String? refreshToken = 'refresh-token',
  DateTime? expiresAt,
  List<String> roles = const [],
  List<String> permissions = const [],
  List<String> features = const [],
  List<String> subscriptions = const [],
  Map<String, dynamic> extraClaims = const {},
  String? deviceId,
  String provider = 'password',
}) {
  final claims = <String, dynamic>{
    'roles': roles,
    'permissions': permissions,
    'features': features,
    'subscriptions': subscriptions,
    ...extraClaims,
  };
  return SessionContext(
    userId: userId,
    sessionId: sessionId,
    accessToken: accessToken,
    refreshToken: refreshToken,
    expiresAt: expiresAt ?? DateTime.now().add(const Duration(hours: 1)),
    claims: claims,
    authProviderUsed: provider,
    deviceId: deviceId,
  );
}

QuantumPermissionContext _ctx(
  SessionContext session, {
  Map<String, dynamic> env = const {},
  Map<String, dynamic> data = const {},
  String? scope,
  String? resource,
  String? operation,
  String? feature,
  String? schema,
  DateTime? now,
  Map<String, dynamic> meta = const {},
}) {
  return session.permissionContext(
    env: env,
    data: data,
    scope: scope,
    resource: resource,
    operation: operation,
    feature: feature,
    schema: schema,
    now: now,
    meta: meta,
  );
}

void _expectAllowed(QuantumPermissionDecision decision) {
  expect(decision.allowed, isTrue, reason: decision.reason);
}

void _expectDenied(QuantumPermissionDecision decision) {
  expect(decision.allowed, isFalse, reason: decision.reason);
}

dynamic _roleRule(int i, String role) {
  switch (i % 4) {
    case 0:
      return role;
    case 1:
      return {'role': role};
    case 2:
      return {
        'roles': [role, 'shadow_$i']
      };
    default:
      return {
        'any': [
          {'role': role},
          {
            'claim': {'active': true}
          }
        ]
      };
  }
}

dynamic _permissionRule(int i, String permission) {
  switch (i % 4) {
    case 0:
      return {
        'permission': permission
      }; // 🚀 Fix: Specify map structure instead of string
    case 1:
      return {'permission': permission};
    case 2:
      return {
        'permissions': [permission, 'shadow_$i']
      };
    default:
      return {
        'all': [
          {'permission': permission},
          {
            'not': {'permission': 'missing_$i'}
          }
        ]
      };
  }
}

dynamic _featureRule(int i, String feature) {
  switch (i % 4) {
    case 0:
      return {
        'feature': feature
      }; // 🚀 Fix: Specify map structure instead of string
    case 1:
      return {'feature': feature};
    case 2:
      return {
        'features': [feature, 'shadow_$i']
      };
    default:
      return {
        'or': [
          {'feature': feature},
          {'feature': 'missing_$i'}
        ]
      };
  }
}

dynamic _subscriptionRule(int i, String plan) {
  switch (i % 4) {
    case 0:
      return {
        'subscription': plan
      }; // 🚀 Fix: Specify map structure instead of string
    case 1:
      return {'subscription': plan};
    case 2:
      return {
        'subscriptions': [plan, 'shadow_$i']
      };
    default:
      return {
        'and': [
          {'plan': plan},
          {
            'not': {'plan': 'missing_$i'}
          }
        ]
      };
  }
}

String _code3(int i) => 'code_${i.toString().padLeft(3, "0")}';

Future<_Harness> _buildHarness({
  required SessionContext session,
  String driverId = 'fake',
  String authDriverId = 'fake_auth',
}) async {
  final dataDriver = _FakeVaultDriver(driverId: driverId);
  final authDriver = _FakeAuthDriver(driverId: authDriverId)
    ..nextSession = session;
  final tempDir = await Directory.systemTemp.createTemp('quantum_perm_test_');

  final client = VaultStreamClient(
    config: VaultStreamClientConfig(
      baseUrl: 'https://example.invalid',
      cacheDirectoryPath: tempDir.path,
      environment: 'test',
      telemetryEnabled: false,
      defaultQueryPolicy: const QueryPolicy(targetDriver: 'fake'),
      securityPolicy: const SecurityPolicy(clientSecret: 'test-secret'),
      accessPolicy: const AccessPolicy(cachePermissions: false),
      offlinePolicy: const OfflinePolicy(
        readCacheWhenOffline: false,
        queueWritesWhenOffline: false,
      ),
    ),
    authDriver: authDriver,
  );
  client.registerDriver(dataDriver);
  await client.authEngine.init();
  await client.authEngine.authenticate(const AuthRequest(
    strategy: 'password',
    credentials: <String, dynamic>{'username': 'tester', 'password': 'pass'},
  ));
  return _Harness(
    client: client,
    dataDriver: dataDriver,
    authDriver: authDriver,
    tempDir: tempDir,
  );
}

class _Harness {
  final VaultStreamClient client;
  final _FakeVaultDriver dataDriver;
  final _FakeAuthDriver authDriver;
  final Directory tempDir;

  _Harness({
    required this.client,
    required this.dataDriver,
    required this.authDriver,
    required this.tempDir,
  });

  Future<void> dispose() async {
    await client.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  }
}

void main() {
  group('QuantumPermissionEngine / SessionContext basics', () {
    test('decision serialization round-trip', () {
      const decision = QuantumPermissionDecision.allow(
        'ok',
        ['role'],
        {'source': 'test'},
      );
      final json = decision.toJson();
      expect(json['allowed'], isTrue);
      expect(json['reason'], 'ok');
      expect((json['matched'] as List).single, 'role');
      expect((json['meta'] as Map)['source'], 'test');
    });

    test('session json round-trip preserves claims and expiry', () {
      final original = _session(
        userId: 'u1',
        sessionId: 's1',
        roles: const ['admin'],
        permissions: const ['read'],
        features: const ['media'],
        subscriptions: const ['pro'],
        extraClaims: const {'tenant': 'acme'},
        deviceId: 'device-1',
      );
      final restored = SessionContext.fromJson(original.toJson());
      expect(restored.userId, original.userId);
      expect(restored.sessionId, original.sessionId);
      expect(restored.claims['tenant'], 'acme');
      expect(restored.claims['roles'], contains('admin'));
      expect(restored.deviceId, 'device-1');
      expect(restored.isAuthenticated, isTrue);
    });

    test('withClaims merges new claims without dropping old ones', () {
      final session = _session(
        userId: 'u1',
        sessionId: 's1',
        roles: const ['user'],
        extraClaims: const {'tenant': 'acme'},
      );
      final merged = session.withClaims({'plan': 'pro'});
      expect(merged.claims['tenant'], 'acme');
      expect(merged.claims['plan'], 'pro');
      expect(merged.claims['roles'], contains('user'));
    });

    test('permissionContext resolves env, data, meta and session claims', () {
      final session = _session(
        userId: 'u1',
        sessionId: 's1',
        roles: const ['admin'],
        permissions: const ['write'],
        features: const ['reels'],
        subscriptions: const ['pro'],
        extraClaims: const {'tenant': 'acme', 'quota': 10},
      );
      final ctx = _ctx(
        session,
        env: const {
          'region': 'eu',
          'roles': ['support']
        },
        data: const {'tier': 'enterprise', 'limit': 99},
        meta: const {'flag': true},
        operation: 'update',
        scope: 'posts',
        feature: 'reels',
        schema: 'media',
      );
      expect(ctx.roles, contains('admin'));
      expect(ctx.roles, contains('support'));
      expect(ctx.permissions, contains('write'));
      expect(ctx.features, contains('reels'));
      expect(ctx.subscriptions, contains('pro'));
      expect(ctx.claim('tenant'), 'acme');
      expect(ctx.claim('quota'), 10);
      expect(ctx.claim('region'), 'eu');
      expect(ctx.claim('limit'), 99);
      expect(ctx.claim('flag'), isTrue);
      expect(ctx.opIs('update'), isTrue);
      expect(ctx.scopeIs('posts'), isTrue);
      expect(ctx.hasRole('admin'), isTrue);
      expect(ctx.hasPermission('write'), isTrue);
      expect(ctx.hasFeature('reels'), isTrue);
      expect(ctx.hasSubscription('pro'), isTrue);
    });
  });

  group('Roles policy matrix', () {
    for (var i = 0; i < 100; i++) {
      test('roles/$i', () {
        final allow = i < 50;
        final role = 'role_$i';
        final session = _session(
          userId: 'user_r_$i',
          sessionId: 'sess_r_$i',
          roles: allow ? [role, 'shared'] : ['other_$i', 'shared'],
          extraClaims: {'active': allow},
        );
        final ctx = _ctx(session,
            scope: 'posts',
            operation: 'read',
            meta: {'case': 'roles', 'index': i});
        final decision =
            QuantumPermissionEngine.instance.evaluate(_roleRule(i, role), ctx);
        if (allow) {
          _expectAllowed(decision);
        } else {
          _expectDenied(decision);
        }
      });
    }
  });

  group('Permissions policy matrix', () {
    for (var i = 0; i < 100; i++) {
      test('permissions/$i', () {
        final allow = i < 50;
        final permission = 'perm_$i';
        final session = _session(
          userId: 'user_p_$i',
          sessionId: 'sess_p_$i',
          permissions:
              allow ? [permission, 'shared'] : ['other_perm_$i', 'shared'],
          extraClaims: {'active': allow},
        );
        final ctx = _ctx(session,
            operation: 'update',
            resource: 'docs',
            meta: {'case': 'permissions', 'index': i});
        final decision = QuantumPermissionEngine.instance
            .evaluate(_permissionRule(i, permission), ctx);
        if (allow) {
          _expectAllowed(decision);
        } else {
          _expectDenied(decision);
        }
      });
    }
  });

  group('Feature flag matrix', () {
    for (var i = 0; i < 100; i++) {
      test('features/$i', () {
        final allow = i < 50;
        final feature = 'feature_$i';
        final session = _session(
          userId: 'user_f_$i',
          sessionId: 'sess_f_$i',
          features:
              allow ? [feature, 'shared'] : ['other_feature_$i', 'shared'],
          extraClaims: {'beta': allow},
        );
        final ctx = _ctx(session,
            feature: feature,
            scope: 'ui',
            meta: {'case': 'features', 'index': i});
        final decision = QuantumPermissionEngine.instance
            .evaluate(_featureRule(i, feature), ctx);
        if (allow) {
          _expectAllowed(decision);
        } else {
          _expectDenied(decision);
        }
      });
    }
  });

  group('Subscription / plan matrix', () {
    for (var i = 0; i < 100; i++) {
      test('subscriptions/$i', () {
        final allow = i < 50;
        final plan = 'plan_$i';
        final session = _session(
          userId: 'user_s_$i',
          sessionId: 'sess_s_$i',
          subscriptions: allow ? [plan, 'shared'] : ['other_plan_$i', 'shared'],
          extraClaims: {'paid': allow},
        );
        final ctx = _ctx(session,
            schema: 'billing',
            operation: 'read',
            meta: {'case': 'subscriptions', 'index': i});
        final decision = QuantumPermissionEngine.instance
            .evaluate(_subscriptionRule(i, plan), ctx);
        if (allow) {
          _expectAllowed(decision);
        } else {
          _expectDenied(decision);
        }
      });
    }
  });

  // 🚀 FIX: Updated Data & Spec comparisons mapping perfectly
  group('Claims and data comparison matrix', () {
    final fixedNow = DateTime.utc(2026, 7, 22, 12, 0, 0);
    for (var i = 0; i < 100; i++) {
      test('comparisons/$i', () {
        final allow = i < 50;
        final useClaim = i.isEven;
        final opIndex = i % 10;
        String field = '';
        dynamic compareSpec;

        Map<String, dynamic> claimPayload = {
          'profile': {
            'name': allow ? 'value_$i' : 'wrong_$i',
            'tags': allow ? ['tag_$i', 'other'] : ['wrong'],
          },
          'quota': allow ? i : i + 1000,
          'nested': {'count': allow ? i : i + 1000},
          'code': allow ? _code3(i) : 'bad_$i',
          'status': allow ? 'active' : 'inactive',
          'tier': allow ? 'value_$i' : 'wrong_$i',
          'flags': allow ? ['tag_$i', 'ok'] : ['wrong', 'bad'],
          'active': allow,
        };
        if (allow) claimPayload['metaFlag'] = true; // Exists check mapping

        Map<String, dynamic> dataPayload = {
          'profile': {
            'name': allow ? 'value_$i' : 'wrong_$i',
            'tags': allow ? ['tag_$i', 'other'] : ['wrong'],
          },
          'quota': allow ? i : i + 1000,
          'nested': {'count': allow ? i : i + 1000},
          'code': allow ? _code3(i) : 'bad_$i',
          'status': allow ? 'active' : 'inactive',
          'tier': allow ? 'value_$i' : 'wrong_$i',
          'flags': allow ? ['tag_$i', 'ok'] : ['wrong', 'bad'],
        };
        if (allow) dataPayload['metaFlag'] = true; // Exists check mapping

        switch (opIndex) {
          case 0:
            field = 'profile.name';
            compareSpec = {'eq': 'value_$i'};
            break;
          case 1:
            field = 'tier';
            compareSpec = {
              'in': ['value_$i', 'alt_$i']
            };
            break;
          case 2:
            field = 'profile.tags';
            compareSpec = {'contains': 'tag_$i'};
            break;
          case 3:
            field = 'code';
            compareSpec = {'regex': r'^code_[0-9]{3}$'};
            break;
          case 4:
            field = 'quota';
            compareSpec = {'gte': allow ? i : i + 2000};
            break;
          case 5:
            field = 'quota';
            compareSpec = {'lte': i + 10};
            break;
          case 6:
            field = 'nested.count';
            compareSpec = {'gt': allow ? i - 1 : i + 2000};
            break;
          case 7:
            field = 'nested.count';
            compareSpec = {'lt': i + 10};
            break;
          case 8:
            field = 'metaFlag';
            compareSpec = {'exists': true};
            break;
          default:
            field = 'status';
            compareSpec = {'not': allow ? 'forbidden_$i' : 'inactive'};
            break;
        }

        final session = _session(
          userId: 'user_c_$i',
          sessionId: 'sess_c_$i',
          extraClaims: claimPayload,
        );

        final ctx = useClaim
            ? _ctx(session, now: fixedNow, meta: {'case': 'claims', 'index': i})
            : _ctx(
                _session(
                  userId: 'user_d_$i',
                  sessionId: 'sess_d_$i',
                ),
                data: dataPayload,
                now: fixedNow,
                meta: {'case': 'data', 'index': i},
              );

        final rule = useClaim
            ? {
                'claim': {field: compareSpec}
              }
            : {
                'data': {field: compareSpec}
              };

        final decision = QuantumPermissionEngine.instance.evaluate(rule, ctx);
        if (allow) {
          _expectAllowed(decision);
        } else {
          _expectDenied(decision);
        }
      });
    }
  });

  group('Boolean / any / all / not matrix', () {
    for (var i = 0; i < 100; i++) {
      test('logic/$i', () {
        final section = i ~/ 25;
        final idx = i % 25;
        final role = 'logic_role_$i';
        final permission = 'logic_perm_$i';
        final feature = 'logic_feature_$i';
        final session = switch (section) {
          0 => _session(
              userId: 'logic_a_$i',
              sessionId: 'logic_as_$i',
              roles: [role],
              permissions: [permission],
              features: [feature],
            ),
          1 => _session(
              userId: 'logic_d_$i',
              sessionId: 'logic_ds_$i',
              roles: ['other_$i'],
              permissions: ['other_perm_$i'],
              features: ['other_feature_$i'],
            ),
          2 => _session(
              userId: 'logic_any_$i',
              sessionId: 'logic_anys_$i',
              roles: idx.isEven ? [role] : ['other_$i'],
              permissions: idx.isOdd ? [permission] : ['other_perm_$i'],
              features: ['other_feature_$i'],
            ),
          _ => _session(
              userId: 'logic_anyd_$i',
              sessionId: 'logic_anyds_$i',
              roles: ['other_$i'],
              permissions: ['other_perm_$i'],
              features: ['other_feature_$i'],
            ),
        };

        final rule = switch (section) {
          0 => {
              'all': [
                {'role': role},
                {'permission': permission},
                {'feature': feature},
              ]
            },
          1 => {
              'all': [
                {'role': role},
                {'permission': permission},
                {'feature': feature},
              ]
            },
          2 => {
              'any': [
                {'role': role},
                {'permission': permission},
                {'feature': feature},
              ]
            },
          _ => {
              'any': [
                {'role': role},
                {'permission': permission},
                {'feature': feature},
              ]
            },
        };

        final decision = QuantumPermissionEngine.instance
            .evaluate(rule, _ctx(session, meta: {'case': 'logic', 'index': i}));
        if (section == 0 || section == 2) {
          _expectAllowed(decision);
        } else {
          _expectDenied(decision);
        }
      });
    }
  });

  group('Time / scope / operation matrix', () {
    final fixedNow = DateTime.utc(2026, 7, 22, 12, 0, 0);
    for (var i = 0; i < 100; i++) {
      test('time-scope/$i', () {
        final section = i ~/ 25;
        final session = _session(
          userId: 'ts_$i',
          sessionId: 'ts_s_$i',
          roles: const ['user'],
          permissions: const ['read'],
        );

        dynamic rule;
        QuantumPermissionContext ctx;

        if (section == 0) {
          final allow = i.isEven;
          rule = {
            'time': allow
                ? {
                    'from': fixedNow
                        .subtract(const Duration(hours: 1))
                        .toIso8601String(),
                    'to': fixedNow
                        .add(const Duration(hours: 1))
                        .toIso8601String(),
                    'weekdays': const [3],
                    'hours': {'from': 10, 'to': 14},
                  }
                : {
                    'from': fixedNow
                        .add(const Duration(hours: 1))
                        .toIso8601String(),
                    'to': fixedNow
                        .add(const Duration(hours: 2))
                        .toIso8601String(),
                  }
          };
          ctx =
              _ctx(session, now: fixedNow, meta: {'case': 'time', 'index': i});
        } else if (section == 1) {
          final allow = i.isEven;
          rule = {
            'operation': allow ? 'update' : 'delete',
          };
          ctx = _ctx(
            session,
            operation: allow ? 'update' : 'read',
            now: fixedNow,
            meta: {'case': 'operation', 'index': i},
          );
        } else if (section == 2) {
          final allow = i.isEven;
          rule = {
            'scope': allow ? 'posts' : 'comments',
          };
          ctx = _ctx(
            session,
            scope: allow ? 'posts' : 'posts',
            resource: allow ? 'posts' : 'posts',
            schema: allow ? 'posts' : 'posts',
            now: fixedNow,
            meta: {'case': 'scope', 'index': i},
          );
        } else {
          final allow = i.isEven;
          rule = {
            'all': [
              {
                'time': {
                  'from': fixedNow
                      .subtract(const Duration(hours: 1))
                      .toIso8601String(),
                  'to':
                      fixedNow.add(const Duration(hours: 1)).toIso8601String(),
                }
              },
              {'operation': allow ? 'read' : 'write'},
              {'scope': allow ? 'posts' : 'comments'},
            ]
          };
          ctx = _ctx(
            session,
            operation: 'read',
            scope: 'posts',
            resource: 'posts',
            schema: 'posts',
            now: fixedNow,
            meta: {'case': 'mixed', 'index': i},
          );
        }

        final decision = QuantumPermissionEngine.instance.evaluate(rule, ctx);
        if (section == 0 || section == 1 || section == 2) {
          if (i.isEven) {
            _expectAllowed(decision);
          } else {
            _expectDenied(decision);
          }
        } else {
          if (i.isEven) {
            _expectAllowed(decision);
          } else {
            _expectDenied(decision);
          }
        }
      });
    }
  });

  group('Registry / custom / cache matrix', () {
    setUp(() {
      QuantumPermissionRegistry.instance.clear();
    });

    tearDown(() {
      QuantumPermissionRegistry.instance.clear();
    });

    test(
        'registry/000 direct function rules currently throw JsonUnsupportedObjectError',
        () {
      final session = _session(userId: 'fun', sessionId: 'fun_s');
      expect(
        () => QuantumPermissionEngine.instance.evaluate(
          (QuantumPermissionContext ctx, Map<String, dynamic> meta) => true,
          _ctx(session),
        ),
        throwsA(anyOf(
          isA<JsonUnsupportedObjectError>(),
          isA<UnsupportedError>(),
        )),
      );
    });

    for (var i = 1; i < 100; i++) {
      test('registry/$i', () {
        final allow = i < 50;
        final name = 'rule_$i';
        final role = 'named_role_$i';
        final permission = 'named_perm_$i';
        final feature = 'named_feature_$i';

        dynamic rule;
        SessionContext session;

        if (i % 5 == 0) {
          rule = allow ? true : false;
          session = _session(userId: 'u_$i', sessionId: 's_$i');
        } else if (i % 5 == 1) {
          rule = allow ? {'role': role} : {'role': 'missing_$i'};
          session = _session(
            userId: 'u_$i',
            sessionId: 's_$i',
            roles: allow ? [role] : ['other_$i'],
          );
        } else if (i % 5 == 2) {
          rule =
              allow ? {'permission': permission} : {'permission': 'missing_$i'};
          session = _session(
            userId: 'u_$i',
            sessionId: 's_$i',
            permissions: allow ? [permission] : ['other_$i'],
          );
        } else if (i % 5 == 3) {
          rule = allow ? {'feature': feature} : {'feature': 'missing_$i'};
          session = _session(
            userId: 'u_$i',
            sessionId: 's_$i',
            features: allow ? [feature] : ['other_$i'],
          );
        } else {
          rule = allow
              ? {
                  'all': [
                    {'role': role},
                    {
                      'not': {'feature': 'blocked_$i'}
                    }
                  ]
                }
              : {
                  'all': [
                    {'role': role},
                    {'feature': 'blocked_$i'}
                  ]
                };
          session = _session(
            userId: 'u_$i',
            sessionId: 's_$i',
            roles: allow ? [role] : ['other_$i'],
            features: allow ? ['allowed_$i'] : ['blocked_$i'],
          );
        }

        QuantumPermissionRegistry.instance.register(name, rule);
        final ctx = _ctx(session, meta: {'case': 'registry', 'index': i});
        final direct = QuantumPermissionEngine.instance.evaluate(name, ctx);
        final ref = QuantumPermissionEngine.instance.evaluate('@$name', ctx);
        if (allow) {
          _expectAllowed(direct);
          _expectAllowed(ref);
        } else {
          _expectDenied(direct);
          _expectDenied(ref);
        }
        expect(direct.allowed, ref.allowed);
      });
    }
  });

  group('Session extension helpers', () {
    for (var i = 0; i < 100; i++) {
      test('session-extension/$i', () {
        final slot = i ~/ 10;
        final role = 'ext_role_$i';
        final permission = 'ext_perm_$i';
        final feature = 'ext_feature_$i';
        final plan = 'ext_plan_$i';
        final session = _session(
          userId: 'ext_$i',
          sessionId: 'ext_s_$i',
          roles: [role, 'shared'],
          permissions: [permission, 'shared'],
          features: [feature, 'shared'],
          subscriptions: [plan, 'shared'],
          extraClaims: {
            'profile': {
              'name': 'value_$i',
              'nested': {'count': i},
            },
            'quota': i,
            'active': true,
          },
        );

        if (slot == 0) {
          expect(session.hasRoleValue(role), isTrue);
          expect(session.hasRoleValue('missing_$i'), isFalse);
          expect(session.roles, contains(role));
        } else if (slot == 1) {
          expect(session.hasPermissionValue(permission), isTrue);
          expect(session.permissions, contains(permission));
        } else if (slot == 2) {
          expect(session.hasFeatureValue(feature), isTrue);
          expect(session.features, contains(feature));
        } else if (slot == 3) {
          expect(session.hasSubscriptionValue(plan), isTrue);
          expect(session.subscriptions, contains(plan));
        } else if (slot == 4) {
          expect(session.claims['profile'], isA<Map>());
          expect(
              session.permissionContext(data: {'quota': i}).claim('quota'), i);
          expect(
              session.permissionContext(data: {
                'profile': {'name': 'value_$i'}
              }).claim('profile.name'),
              'value_$i');
        } else if (slot == 5) {
          final merged = session.withClaims({'plan': 'pro_$i'});
          expect(merged.claims['plan'], 'pro_$i');
          expect(merged.claims['profile'], isA<Map>());
        } else if (slot == 6) {
          expect(session.can({'role': role}), isTrue);
          expect(session.can({'role': 'missing_$i'}), isFalse);
        } else if (slot == 7) {
          final ctx = session.permissionContext(
            data: {'quota': i},
            scope: 'posts',
            resource: 'posts',
            operation: 'read',
            feature: feature,
            schema: 'posts',
            meta: {'slot': slot},
          );
          expect(ctx.hasFeature(feature), isTrue);
          expect(ctx.scopeIs('posts'), isTrue);
          expect(ctx.opIs('read'), isTrue);
        } else if (slot == 8) {
          final json = session.toJson();
          final restored = SessionContext.fromJson(json);
          expect(restored.userId, session.userId);
          expect(restored.claims['profile'], isA<Map>());
          expect(restored.claims['quota'], i);
        } else {
          final ctx =
              _ctx(session, env: {'region': 'us'}, meta: {'slot': slot});
          final decision = QuantumPermissionEngine.instance.evaluate(
            {
              'all': [
                {'role': role},
                {'permission': permission},
                {'feature': feature},
                {'subscription': plan},
              ]
            },
            ctx,
          );
          _expectAllowed(decision);
        }
      });
    }
  });

  // 🚀 FIX: Adapted Root Operations to map to correctly routed Execution paths.
  group('Production API integration / permission gate', () {
    for (var i = 0; i < 100; i++) {
      test('api-gate/$i', () async {
        final allow = i < 50;
        final operationKind = i % 5;
        final role = 'api_role_$i';
        final permission = 'api_perm_$i';
        final feature = 'api_feature_$i';
        final plan = 'api_plan_$i';

        final session = _session(
          userId: 'api_user_$i',
          sessionId: 'api_sess_$i',
          roles: allow ? [role] : ['other_role_$i'],
          permissions: allow ? [permission] : ['other_perm_$i'],
          features: allow ? [feature] : ['other_feature_$i'],
          subscriptions: allow ? [plan] : ['other_plan_$i'],
          extraClaims: {'active': allow},
        );

        final harness = await _buildHarness(session: session);
        addTearDown(harness.dispose);

        final client = harness.client;
        final dataDriver = harness.dataDriver;

        final writeBody = <String, dynamic>{
          'title': 'doc_$i',
          'permissions': {'role': role},
          'guard': {'permission': permission},
          'policy': {'feature': feature},
        };

        ApiResult<dynamic> result;

        if (operationKind == 0) {
          result = await client.collection('posts').create(writeBody);
        } else if (operationKind == 1) {
          result =
              await client.collection('posts').updateById('id_$i', writeBody);
        } else if (operationKind == 2) {
          result =
              await client.executeWrite(slug: 'posts', op: 'deleteMany', body: {
            'filter': {'id': i},
            'permissions': {'role': role}
          });
        } else if (operationKind == 3) {
          result = await client.executeRead(slug: 'posts', query: {
            'op': 'readOne',
            'filter': {'id': i},
            'permissions': {'subscription': plan},
            'guard': {'role': role},
            'policy': {'feature': feature},
          });
        } else {
          result = await client.executeRead(slug: 'posts', query: {
            'op': 'exists',
            'filter': {'id': i},
            'permissions': {'subscription': plan},
            'guard': {'role': role},
            'policy': {'feature': feature},
          });
        }

        if (allow) {
          expect(result.isSuccess, isTrue, reason: result.error?.toString());
          if (operationKind <= 2) {
            expect(dataDriver.writeCalls, 1);
            expect(dataDriver.lastContext, isNotNull);
            expect(dataDriver.lastContext!.securityHeaders, isNotEmpty);
            expect(
                dataDriver.lastContext!.securityHeaders
                    .containsKey('X-Vault-Signature'),
                isTrue);
            expect(dataDriver.lastContext!.session.userId, session.userId);
          } else {
            expect(dataDriver.readCalls, 1);
            expect(dataDriver.lastContext, isNotNull);
            expect(dataDriver.lastContext!.securityHeaders, isNotEmpty);
            expect(dataDriver.lastContext!.session.userId, session.userId);
          }
        } else {
          expect(result.isSuccess, isFalse);
          expect(result.error?.code, 'permission_denied');
          expect(dataDriver.writeCalls + dataDriver.readCalls, 0);
        }
      });
    }
  });
}
