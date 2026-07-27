// =============================================================================
// quantum_firebase_adapters.dart
// =============================================================================

import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_database/firebase_database.dart' as rtdb;
import 'package:firebase_storage/firebase_storage.dart' as fb_storage;
import 'dart:io'; // <-- Add this import

// Import your engines here
import '../quantum_api_engine.dart';
import '../quantum_auth_engine.dart';
import '../quantum_media_api.dart';
import '../quantum_socket_engine.dart';
import '../internal/quantum_socket_stream_hub.dart';
// =============================================================================
// 1. FIREBASE AUTHENTICATION DRIVER
// =============================================================================

class FirebaseAuthDriver implements AuthDriver {
  @override
  final String driverId = 'firebase_auth';

  @override
  final AuthCapabilities capabilities = const AuthCapabilities(
    register: true,
    login: true,
    otp: true,
    passkey:
        false, // Firebase natively uses standard creds, passkeys require specialized extensions
    providerLogin: true,
    providerLinking: true,
    refresh: true,
    revoke: true,
    profileUpdates: true,
    passwordOperations: true,
    emailVerification: true,
    accountUnlock: false, // Handled automatically by Firebase
    discovery: true,
  );

  final fb_auth.FirebaseAuth _fbAuth;

  FirebaseAuthDriver({fb_auth.FirebaseAuth? authInstance})
      : _fbAuth = authInstance ?? fb_auth.FirebaseAuth.instance;

  Future<SessionContext> _mapUserToSession(fb_auth.User? user,
      {String provider = 'firebase'}) async {
    if (user == null) return const SessionContext();
    Map<String, dynamic> tokenClaims = const <String, dynamic>{};
    try {
      final idTokenResult = await user.getIdTokenResult();
      tokenClaims = (idTokenResult.claims ?? const <String, dynamic>{})
          .cast<String, dynamic>();
    } catch (_) {
      tokenClaims = const <String, dynamic>{};
    }
    return SessionContext(
      userId: user.uid,
      sessionId: user.uid, // Firebase treats device tokens as session concepts
      accessToken:
          'firebase_token_proxy', // Handled under the hood via idTokens
      refreshToken: user.refreshToken,
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      claims: {
        'email': user.email,
        'emailVerified': user.emailVerified,
        'displayName': user.displayName,
        'phoneNumber': user.phoneNumber,
        'photoURL': user.photoURL,
        'roles': tokenClaims['roles'] ?? tokenClaims['role'] ?? ['user'],
        ...tokenClaims,
      },
      authProviderUsed: provider,
    );
  }

  AuthException _mapFirebaseError(dynamic e) {
    if (e is fb_auth.FirebaseAuthException) {
      return AuthException(e.code, e.message ?? 'Firebase Auth Error',
          details: e.stackTrace);
    }
    return AuthException('unknown', e.toString());
  }

  @override
  Future<void> initialize(Map<String, dynamic> config) async {
    // Firebase relies on initialization at the app level.
  }

  @override
  Future<AuthResult<SessionContext>> register(AuthRequest request) async {
    try {
      final email = request.credentials['email']?.toString();
      final password = request.credentials['password']?.toString();
      if (email == null || password == null)
        throw const AuthException('invalid', 'Email/Password missing');

      final cred = await _fbAuth.createUserWithEmailAndPassword(
          email: email, password: password);
      return AuthResult.success(
          await _mapUserToSession(cred.user, provider: 'emailPassword'),
          driverUsed: driverId);
    } catch (e) {
      return AuthResult.failure(_mapFirebaseError(e), driverUsed: driverId);
    }
  }

  @override
  Future<AuthResult<SessionContext>> login(AuthRequest request) async {
    try {
      final email = request.credentials['email']?.toString();
      final password = request.credentials['password']?.toString();
      if (email == null || password == null)
        throw const AuthException('invalid', 'Email/Password missing');

      final cred = await _fbAuth.signInWithEmailAndPassword(
          email: email, password: password);
      return AuthResult.success(
          await _mapUserToSession(cred.user, provider: 'emailPassword'),
          driverUsed: driverId);
    } catch (e) {
      return AuthResult.failure(_mapFirebaseError(e), driverUsed: driverId);
    }
  }

  @override
  Future<AuthResult<SessionContext>> refreshSession(
      SessionContext currentSession) async {
    try {
      final user = _fbAuth.currentUser;
      if (user == null)
        throw const AuthException('no_session', 'User not logged in');
      await user.getIdToken(true); // Force token refresh
      return AuthResult.success(
          await _mapUserToSession(user,
              provider: currentSession.authProviderUsed),
          driverUsed: driverId);
    } catch (e) {
      return AuthResult.failure(_mapFirebaseError(e), driverUsed: driverId);
    }
  }

  @override
  Future<AuthResult<void>> revokeSession(SessionContext session) async =>
      logout(session);

  @override
  Future<AuthResult<void>> logout(SessionContext session) async {
    try {
      await _fbAuth.signOut();
      return const AuthResult.success(null);
    } catch (e) {
      return AuthResult.failure(_mapFirebaseError(e), driverUsed: driverId);
    }
  }

  // --- OTP (Firebase Phone Auth) ---
  final Map<String, String> _verificationIds = {};

  @override
  Future<AuthResult<AuthChallenge>> requestOtp(AuthChallenge request) async {
    if (request.destination == null)
      return AuthResult.failure(
          const AuthException('invalid', 'Missing phone number'),
          driverUsed: driverId);

    final completer = Completer<AuthResult<AuthChallenge>>();

    await _fbAuth.verifyPhoneNumber(
      phoneNumber: request.destination!,
      verificationCompleted: (fb_auth.PhoneAuthCredential credential) async {
        // Auto-resolution (Android mostly)
      },
      verificationFailed: (fb_auth.FirebaseAuthException e) {
        completer.complete(
            AuthResult.failure(_mapFirebaseError(e), driverUsed: driverId));
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationIds[request.destination!] = verificationId;
        completer.complete(AuthResult.success(request, driverUsed: driverId));
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationIds[request.destination!] = verificationId;
      },
    );

    return completer.future;
  }

  @override
  Future<AuthResult<SessionContext>> verifyOtp(
      AuthChallenge challenge, String code) async {
    try {
      final verificationId = _verificationIds[challenge.destination];
      if (verificationId == null)
        throw const AuthException('timeout', 'Verification session expired');

      final credential = fb_auth.PhoneAuthProvider.credential(
          verificationId: verificationId, smsCode: code);
      final cred = await _fbAuth.signInWithCredential(credential);
      return AuthResult.success(
          await _mapUserToSession(cred.user, provider: 'phone'),
          driverUsed: driverId);
    } catch (e) {
      return AuthResult.failure(_mapFirebaseError(e), driverUsed: driverId);
    }
  }

  // --- Profile & Password Management ---

  @override
  Future<AuthResult<SessionContext>> updateProfile(Map<String, dynamic> profile,
      {required SessionContext currentSession}) async {
    try {
      final user = _fbAuth.currentUser;
      if (user == null)
        throw const AuthException('no_session', 'Not logged in');

      if (profile.containsKey('displayName'))
        await user.updateDisplayName(profile['displayName']);
      if (profile.containsKey('photoURL'))
        await user.updatePhotoURL(profile['photoURL']);

      await user.reload();
      return AuthResult.success(
          await _mapUserToSession(_fbAuth.currentUser,
              provider: currentSession.authProviderUsed),
          driverUsed: driverId);
    } catch (e) {
      return AuthResult.failure(_mapFirebaseError(e), driverUsed: driverId);
    }
  }

  @override
  Future<AuthResult<void>> verifyEmail(String token) async {
    try {
      await _fbAuth.checkActionCode(token);
      await _fbAuth.applyActionCode(token);
      return const AuthResult.success(null);
    } catch (e) {
      return AuthResult.failure(_mapFirebaseError(e), driverUsed: driverId);
    }
  }

  @override
  Future<AuthResult<void>> resendVerification() async {
    try {
      await _fbAuth.currentUser?.sendEmailVerification();
      return const AuthResult.success(null);
    } catch (e) {
      return AuthResult.failure(_mapFirebaseError(e), driverUsed: driverId);
    }
  }

  @override
  Future<AuthResult<void>> forgotPassword(String email) async {
    try {
      await _fbAuth.sendPasswordResetEmail(email: email);
      return const AuthResult.success(null);
    } catch (e) {
      return AuthResult.failure(_mapFirebaseError(e), driverUsed: driverId);
    }
  }

  @override
  Future<AuthResult<AuthChallenge>> beginBiometricAuth(
      AuthRequest request) async {
    return AuthResult.failure(
        const AuthException('unsupported',
            'Biometric auth not natively supported by Firebase Web/REST without custom claims plugins.'),
        driverUsed: driverId);
  }

  @override
  Future<AuthResult<SessionContext>> completeBiometricAuth(
      AuthRequest request) async {
    return AuthResult.failure(
        const AuthException('unsupported',
            'Biometric auth not natively supported by Firebase Web/REST.'),
        driverUsed: driverId);
  }

  @override
  Future<AuthResult<void>> resetPassword(
      {required String token, required String password}) async {
    try {
      await _fbAuth.confirmPasswordReset(code: token, newPassword: password);
      return const AuthResult.success(null);
    } catch (e) {
      return AuthResult.failure(_mapFirebaseError(e), driverUsed: driverId);
    }
  }

  @override
  Future<AuthResult<SessionContext>> changePassword(
      {required SessionContext currentSession,
      required String oldPassword,
      required String newPassword}) async {
    try {
      final user = _fbAuth.currentUser;
      if (user == null)
        throw const AuthException('no_session', 'Not logged in');

      final cred = fb_auth.EmailAuthProvider.credential(
          email: user.email!, password: oldPassword);
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);

      return AuthResult.success(
          await _mapUserToSession(user,
              provider: currentSession.authProviderUsed),
          driverUsed: driverId);
    } catch (e) {
      return AuthResult.failure(_mapFirebaseError(e), driverUsed: driverId);
    }
  }

  @override
  Future<AuthResult<void>> unlockAccount(String token) async =>
      const AuthResult.success(
          null); // Managed by Firebase Security automatically

  @override
  Future<AuthResult<void>> revokeAllSessions(
      SessionContext currentSession) async {
    // Requires Firebase Admin SDK on backend, local client can only log themselves out.
    return logout(currentSession);
  }

  // --- External Providers ---
  @override
  Future<AuthResult<SessionContext>> linkProvider(
      AuthProvider provider, AuthRequest request) async {
    try {
      // In a real app, you would pass the credential in the request credentials map
      // e.g., fb_auth.GoogleAuthProvider.credential(idToken: ...)
      final fb_auth.AuthCredential credential =
          request.credentials['credential'];
      final cred = await _fbAuth.currentUser?.linkWithCredential(credential);
      return AuthResult.success(
          await _mapUserToSession(cred?.user, provider: provider.name),
          driverUsed: driverId);
    } catch (e) {
      return AuthResult.failure(_mapFirebaseError(e), driverUsed: driverId);
    }
  }

  @override
  Future<AuthResult<SessionContext>> unlinkProvider(
      AuthProvider provider, AuthRequest request) async {
    try {
      final user = await _fbAuth.currentUser?.unlink(provider.name);
      return AuthResult.success(
          await _mapUserToSession(user, provider: 'emailPassword'),
          driverUsed: driverId);
    } catch (e) {
      return AuthResult.failure(_mapFirebaseError(e), driverUsed: driverId);
    }
  }

  @override
  Future<AuthResult<List<String>>> discoverAuthMethods(
      AuthRequest request) async {
    return AuthResult.success(['emailPassword', 'google', 'apple', 'phone'],
        driverUsed: driverId);
  }

  // --- Passkeys & Unused (Throw explicit unsupported) ---
  @override
  Future<AuthResult<AuthChallenge>> beginPasskeyRegistration(
          AuthRequest request) async =>
      AuthResult.failure(
          const AuthException('unsupported',
              'Use native Passkey plugin & Firebase Custom Tokens'),
          driverUsed: driverId);
  @override
  Future<AuthResult<SessionContext>> completePasskeyRegistration(
          AuthRequest request) async =>
      AuthResult.failure(
          const AuthException('unsupported', 'Use native Passkey plugin'),
          driverUsed: driverId);
  @override
  Future<AuthResult<AuthChallenge>> beginPasskeyAuthentication(
          AuthRequest request) async =>
      AuthResult.failure(
          const AuthException('unsupported', 'Use native Passkey plugin'),
          driverUsed: driverId);
  @override
  Future<AuthResult<SessionContext>> completePasskeyAuthentication(
          AuthRequest request) async =>
      AuthResult.failure(
          const AuthException('unsupported', 'Use native Passkey plugin'),
          driverUsed: driverId);
  @override
  Future<AuthResult<AuthChallenge>> confirmOperation(
          AuthRequest request) async =>
      AuthResult.failure(
          const AuthException('unsupported', 'Requires Firebase MFA Setup'),
          driverUsed: driverId);
  @override
  Future<AuthResult<Map<String, dynamic>>> getAuthPolicy() async =>
      const AuthResult.success({'provider': 'firebase'},
          driverUsed: 'firebase_auth');

  @override
  Future<void> dispose() async {}
}

// =============================================================================
// 2. FIRESTORE DATA DRIVER
// =============================================================================

class FirebaseApiDriver implements VaultDriver {
  @override
  final String driverId = 'firebase_firestore';
  final firestore.FirebaseFirestore _db = firestore.FirebaseFirestore.instance;

  @override
  Future<void> initialize(Map<String, dynamic> config) async {
    _db.settings = const firestore.Settings(
        persistenceEnabled: false); // We handle offline in Quantum!
  }

  VaultStreamException _handleError(dynamic e) {
    if (e is firestore.FirebaseException) {
      return VaultStreamException(e.code, e.message ?? 'Firestore error',
          details: e.stackTrace);
    }
    return VaultStreamException('unknown', e.toString());
  }

  List<String> _selectFields(Map<String, dynamic> query) {
    return (query['select'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList(growable: false) ??
        const <String>[];
  }

  firestore.Query<Map<String, dynamic>> _applyQuery(
      firestore.Query<Map<String, dynamic>> ref, Map<String, dynamic> query) {
    var mappedRef = ref;

    // Process "where" filters
    if (query.containsKey('filter')) {
      final filter = query['filter'] as Map<String, dynamic>;
      filter.forEach((k, v) {
        if (v is Map) {
          if (v.containsKey('>')) {
            mappedRef = mappedRef.where(k, isGreaterThan: v['>']);
          }
          if (v.containsKey('>=')) {
            mappedRef = mappedRef.where(k, isGreaterThanOrEqualTo: v['>=']);
          }
          if (v.containsKey('<')) {
            mappedRef = mappedRef.where(k, isLessThan: v['<']);
          }
          if (v.containsKey('<=')) {
            mappedRef = mappedRef.where(k, isLessThanOrEqualTo: v['<=']);
          }
          if (v.containsKey('in')) {
            mappedRef = mappedRef.where(k, whereIn: v['in']);
          }
          if (v.containsKey('contains')) {
            mappedRef = mappedRef.where(k, arrayContains: v['contains']);
          }
        } else {
          mappedRef = mappedRef.where(k, isEqualTo: v);
        }
      });
    }

    // NOTE: The Flutter Firestore client SDK does not support .select()
    // If field limiting is required, it must be handled client-side after fetching.

    if (query.containsKey('sort')) {
      final sort = query['sort'] as Map<String, dynamic>;
      mappedRef = mappedRef.orderBy(sort['field'],
          descending: sort['descending'] ?? false);
    }

    if (query.containsKey('startAfter')) {
      mappedRef = mappedRef.startAfter(query['startAfter']);
    }
    if (query.containsKey('startAt')) {
      mappedRef = mappedRef.startAt(query['startAt']);
    }
    if (query.containsKey('endBefore')) {
      mappedRef = mappedRef.endBefore(query['endBefore']);
    }
    if (query.containsKey('endAt')) {
      mappedRef = mappedRef.endAt(query['endAt']);
    }

    // NOTE: The Flutter Firestore client SDK does not support .offset() natively.
    // Pagination must be handled strictly through the cursors above.

    if (query.containsKey('limitToLast')) {
      mappedRef = mappedRef.limitToLast(query['limitToLast']);
    }
    if (query.containsKey('limit')) {
      mappedRef = mappedRef.limit(query['limit']);
    }

    return mappedRef;
  }

  @override
  Future<ApiResult<dynamic>> read(String slug, Map<String, dynamic> query,
      {String? id, required DriverContext context}) async {
    try {
      final op = query['op']?.toString();
      if (id != null) {
        if (op == 'exists') {
          final doc = await _db.collection(slug).doc(id).get();
          return ApiResult.success({'exists': doc.exists},
              driverUsed: driverId);
        }

        final selectFields = _selectFields(query);
        if (selectFields.isNotEmpty) {
          var ref = _db
              .collection(slug)
              .where(firestore.FieldPath.documentId, isEqualTo: id);
          ref = _applyQuery(ref, query);
          final snap = await ref.limit(1).get();
          if (snap.docs.isEmpty) {
            throw const VaultStreamException(
                'not_found', 'Document does not exist');
          }
          final doc = snap.docs.first;
          return ApiResult.success(
              {'id': doc.id, ...(doc.data() as Map<String, dynamic>)},
              driverUsed: driverId);
        }

        final doc = await _db.collection(slug).doc(id).get();
        if (!doc.exists) {
          throw const VaultStreamException(
              'not_found', 'Document does not exist');
        }
        return ApiResult.success({'id': doc.id, ...?doc.data()},
            driverUsed: driverId);
      } else {
        final ref = _applyQuery(_db.collection(slug), query);
        final snap = await ref.get();
        if (op == 'count') {
          return ApiResult.success({'count': snap.size, 'items': const []},
              driverUsed: driverId);
        }
        if (op == 'exists') {
          return ApiResult.success({'exists': snap.docs.isNotEmpty},
              driverUsed: driverId);
        }
        final items = snap.docs
            .map((d) => <String, dynamic>{
                  'id': d.id,
                  ...(d.data() as Map<String, dynamic>)
                })
            .toList(growable: false);
        return ApiResult.success({'items': items, 'count': items.length},
            driverUsed: driverId);
      }
    } catch (e) {
      return ApiResult.failure(_handleError(e), driverUsed: driverId);
    }
  }

  @override
  Future<ApiResult<dynamic>> write(
      String slug, String op, Map<String, dynamic> body,
      {String? id, required DriverContext context}) async {
    try {
      final collection = _db.collection(slug);

      switch (op) {
        case 'create':
          final doc = id != null ? collection.doc(id) : collection.doc();
          await doc.set(body);
          return ApiResult.success({'id': doc.id, ...body},
              driverUsed: driverId);

        case 'createMany':
          final items =
              (body['items'] as List?)?.cast<Map<String, dynamic>>() ??
                  const <Map<String, dynamic>>[];
          final batch = _db.batch();
          final created = <Map<String, dynamic>>[];
          for (final item in items) {
            final doc = collection.doc();
            batch.set(doc, item);
            created.add({'id': doc.id, ...item});
          }
          await batch.commit();
          return ApiResult.success({'items': created, 'count': created.length},
              driverUsed: driverId);

        case 'updateById':
        case 'patchById':
          if (id == null) {
            throw const VaultStreamException(
                'missing_id', 'ID required for update');
          }
          await collection.doc(id).update(body);
          return ApiResult.success({'id': id, 'updated': true},
              driverUsed: driverId);

        case 'updateMany':
          final filter = (body['filter'] as Map<String, dynamic>?) ??
              const <String, dynamic>{};
          final data = (body['data'] as Map<String, dynamic>?) ??
              const <String, dynamic>{};
          final snap = await _applyQuery(collection, {'filter': filter}).get();
          final batch = _db.batch();
          for (final doc in snap.docs) {
            batch.update(doc.reference, data);
          }
          await batch.commit();
          return ApiResult.success({'updated': snap.docs.length},
              driverUsed: driverId);

        case 'upsertById':
          if (id == null) {
            throw const VaultStreamException(
                'missing_id', 'ID required for upsert');
          }
          await collection.doc(id).set(body, firestore.SetOptions(merge: true));
          return ApiResult.success({'id': id, 'upserted': true},
              driverUsed: driverId);

        case 'deleteById':
          if (id == null) {
            throw const VaultStreamException(
                'missing_id', 'ID required for delete');
          }
          await collection.doc(id).delete();
          return ApiResult.success({'id': id, 'deleted': true},
              driverUsed: driverId);

        case 'deleteMany':
          final filter = (body['filter'] as Map<String, dynamic>?) ??
              const <String, dynamic>{};
          final snap = await _applyQuery(collection, {'filter': filter}).get();
          final batch = _db.batch();
          for (final doc in snap.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
          return ApiResult.success({'deleted': snap.docs.length},
              driverUsed: driverId);

        default:
          throw VaultStreamException('unsupported_op',
              'Operation $op not supported in Firebase Driver');
      }
    } catch (e) {
      return ApiResult.failure(_handleError(e), driverUsed: driverId);
    }
  }

  @override
  Stream<ApiResult<dynamic>> subscribe(String slug, Map<String, dynamic> query,
      {required DriverContext context}) {
    final ref = _applyQuery(_db.collection(slug), query);
    return ref.snapshots().map((snap) {
      final items = snap.docs
          .map((d) => <String, dynamic>{
                'id': d.id,
                ...(d.data() as Map<String, dynamic>)
              })
          .toList();
      return ApiResult.success({'items': items, 'count': items.length},
          driverUsed: driverId);
    }).handleError((e) {
      return ApiResult.failure(_handleError(e), driverUsed: driverId);
    });
  }

  @override
  Future<void> dispose() async {}
}

// =============================================================================
// 3. FIREBASE REALTIME DATABASE SOCKET DRIVER
// =============================================================================

class FirebaseSocketDriver
    extends QLSocketDriverBase<SocketState, SocketMessage>
    implements SocketDriver {
  @override
  final String driverId = 'firebase_rtdb_socket';

  final rtdb.FirebaseDatabase _db = rtdb.FirebaseDatabase.instance;

  final Map<String, StreamSubscription> _channelSubscriptions = {};
  StreamSubscription? _connectionSub;

  @override
  Future<void> connect(String url, Map<String, dynamic> options) async {
    emitState(SocketState.connecting);
    _db.goOnline();

    _connectionSub = _db.ref('.info/connected').onValue.listen((event) {
      final connected = event.snapshot.value as bool? ?? false;
      if (connected) {
        emitState(SocketState.connected);
      } else {
        emitState(SocketState.reconnecting);
      }
    });
  }

  @override
  Future<void> send(SocketMessage message) async {
    if (message.pattern == SocketPattern.system) {
      if (message.event == 'subscribe') {
        _subscribeToFirebaseNode(message.payload['channel']);
      } else if (message.event == 'unsubscribe') {
        _unsubscribeFromFirebaseNode(message.payload['channel']);
      }
      return;
    }

    // Push the message to the specific RTDB channel
    final ref = _db.ref('quantum_sockets/${message.channel}').push();
    await ref.set(message.toMap());
  }

  void _subscribeToFirebaseNode(String channel) {
    if (_channelSubscriptions.containsKey(channel)) return;

    final ref = _db.ref('quantum_sockets/$channel');
    final query =
        ref.orderByChild('ts').startAt(DateTime.now().millisecondsSinceEpoch);

    _channelSubscriptions[channel] = query.onChildAdded.listen((event) {
      if (event.snapshot.value != null) {
        try {
          final map = Map<String, dynamic>.from(event.snapshot.value as Map);
          emitMessage(SocketMessage.fromMap(map));
        } catch (e, st) {
          // Previously swallowed entirely (catch (_) {}), which meant a
          // single malformed RTDB payload on a channel would vanish with no
          // trace -- indistinguishable from "no message was sent". Route it
          // through the existing message stream's error channel instead, so
          // callers of `onMessage` can observe/log it via
          // `.listen(..., onError: ...)` the same way they'd see any other
          // socket error, without changing this driver's public API.
          emitMessageError(
            StateError(
              'Failed to parse Firebase RTDB payload on channel '
              '"$channel": $e',
            ),
            st,
          );
        }
      }
    });
  }

  void _unsubscribeFromFirebaseNode(String channel) {
    _channelSubscriptions[channel]?.cancel();
    _channelSubscriptions.remove(channel);
  }

  @override
  Future<void> sendRawBinary(Uint8List data) async {
    // RTDB doesn't natively support raw binary firehoses well.
    // Usually converted to base64 string, but it's slow.
    // Ignored for Firebase RTDB, highly recommend standard WebSockets for video VoIP.
  }

  @override
  Future<void> disconnect() async {
    await _connectionSub?.cancel();
    for (var sub in _channelSubscriptions.values) {
      await sub.cancel();
    }
    _channelSubscriptions.clear();
    _db.goOffline();
    emitState(SocketState.disconnected);
  }
}

// =============================================================================
// 4. FIREBASE MEDIA BRIDGE (STORAGE ADAPTER)
// =============================================================================

/// Acts as a bridge between QuantumMediaEngine and Firebase Cloud Storage.
class FirebaseMediaStorageBridge {
  final fb_storage.FirebaseStorage _storage =
      fb_storage.FirebaseStorage.instance;

  /// Uploads a file using Quantum's TransferProgress format seamlessly.
  Stream<TransferProgress> uploadFile(
      {required String localFilePath, required String firebasePath}) {
    final controller = StreamController<TransferProgress>();
    final ref = _storage.ref().child(firebasePath);
    final uploadTask = ref.putFile(
        File(localFilePath)); // <-- FIXED: Changed java.io.File to Dart's File

    uploadTask.snapshotEvents.listen((event) {
      final double progress = event.bytesTransferred / event.totalBytes;

      controller.add(TransferProgress(
        sentBytes: event.bytesTransferred,
        totalBytes: event.totalBytes,
        progress: progress,
        stage: event.state.name,
        currentSpeedBps:
            0.0, // Firebase SDK doesn't natively expose speed metrics
        estimatedTimeRemaining: const Duration(seconds: 0),
      ));

      if (event.state == fb_storage.TaskState.success) {
        controller.close();
      } else if (event.state == fb_storage.TaskState.error) {
        controller.addError(
            VaultStreamException('upload_failed', 'Firebase storage error'));
        controller.close();
      }
    });

    return controller.stream;
  }

  /// Gets a standard HTTP URL that QuantumMediaEngine's Proxy Server can ingest.
  Future<String> getDownloadUrl(String firebasePath) async {
    final ref = _storage.ref().child(firebasePath);
    return await ref.getDownloadURL();
  }
}
