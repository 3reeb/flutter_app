// =============================================================================
// session.dart — User session context and auth provider interfaces.
// No platform-specific imports.
// =============================================================================

import 'dart:async';

// ---------------------------------------------------------------------------
// Auth Provider Interface
// ---------------------------------------------------------------------------

/// Abstract interface for supplying session tokens to the network stack.
/// Implement this to integrate any auth backend (Firebase, Supabase, custom).
abstract class AuthProvider {
  /// Returns the current session, or null if not authenticated.
  Future<SessionContext?> getSession();

  /// Stream that emits whenever the session changes (login, logout, refresh).
  Stream<SessionContext?> get onSessionChanged;
}

// ---------------------------------------------------------------------------
// Session Store
// ---------------------------------------------------------------------------

/// Simple in-memory session holder that also implements [AuthProvider].
/// Broadcasts changes to all listeners via a broadcast stream.
class SessionStore implements AuthProvider {
  SessionContext? _session;
  final StreamController<SessionContext?> _controller =
      StreamController<SessionContext?>.broadcast();

  SessionStore([this._session]);

  /// Replace the active session and notify all subscribers.
  void setSession(SessionContext? session) {
    _session = session;
    if (!_controller.isClosed) _controller.add(session);
  }

  @override
  Future<SessionContext?> getSession() async => _session;

  @override
  Stream<SessionContext?> get onSessionChanged => _controller.stream;

  void dispose() {
    if (!_controller.isClosed) _controller.close();
  }
}

// ---------------------------------------------------------------------------
// Session Context
// ---------------------------------------------------------------------------

/// Immutable snapshot of the user's authentication state.
///
/// Carries the access token, optional refresh token, expiry timestamp,
/// and arbitrary JWT claims. All claim accessors are zero-allocation
/// (they parse from the [claims] map lazily).
class SessionContext {
  final String? userId;
  final String? sessionId;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final Map<String, dynamic> claims;
  final String authProviderUsed;
  final String? deviceId;

  const SessionContext({
    this.userId,
    this.sessionId,
    this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.claims = const {},
    this.authProviderUsed = 'none',
    this.deviceId,
  });

  /// True when [userId] and [accessToken] are both present.
  bool get isAuthenticated => userId != null && accessToken != null;

  /// True when the token is past its [expiresAt] timestamp.
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  // ---- Serialisation -------------------------------------------------------

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'sessionId': sessionId,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'expiresAt': expiresAt?.toIso8601String(),
        'claims': claims,
        'authProviderUsed': authProviderUsed,
        'deviceId': deviceId,
      };

  factory SessionContext.fromJson(Map<String, dynamic> json) => SessionContext(
        userId: json['userId'] as String?,
        sessionId: json['sessionId'] as String?,
        accessToken: json['accessToken'] as String?,
        refreshToken: json['refreshToken'] as String?,
        expiresAt: json['expiresAt'] != null
            ? DateTime.parse(json['expiresAt'] as String)
            : null,
        claims:
            (json['claims'] as Map?)?.cast<String, dynamic>() ?? const {},
        authProviderUsed: json['authProviderUsed'] as String? ?? 'unknown',
        deviceId: json['deviceId'] as String?,
      );

  SessionContext copyWith({
    String? userId,
    String? sessionId,
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    Map<String, dynamic>? claims,
    String? authProviderUsed,
    String? deviceId,
  }) =>
      SessionContext(
        userId: userId ?? this.userId,
        sessionId: sessionId ?? this.sessionId,
        accessToken: accessToken ?? this.accessToken,
        refreshToken: refreshToken ?? this.refreshToken,
        expiresAt: expiresAt ?? this.expiresAt,
        claims: claims ?? this.claims,
        authProviderUsed: authProviderUsed ?? this.authProviderUsed,
        deviceId: deviceId ?? this.deviceId,
      );

  // ---- Claim Accessors -----------------------------------------------------

  List<String> _toStringList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is String) return [raw];
    if (raw is Iterable) {
      return raw
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList(growable: false);
    }
    return [raw.toString()];
  }

  List<String> get roles => _toStringList(claims['roles'] ?? claims['role']);
  List<String> get permissions =>
      _toStringList(claims['permissions'] ?? claims['permission']);
  List<String> get features => _toStringList(
      claims['features'] ?? claims['featureFlags'] ?? claims['feature']);
  List<String> get subscriptions => _toStringList(
      claims['subscriptions'] ?? claims['subscription'] ?? claims['plan']);

  bool hasRole(String role) => roles.contains(role);
  bool hasPermission(String perm) => permissions.contains(perm);
  bool hasFeature(String feat) => features.contains(feat);
  bool hasSubscription(String sub) => subscriptions.contains(sub);

  /// Generic claim accessor. Returns the raw claim value for [key].
  dynamic claim(String key) => claims[key];
}
