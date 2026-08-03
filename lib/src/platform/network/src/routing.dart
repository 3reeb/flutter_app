// =============================================================================
// routing.dart — Route manifests and host policies.
// RouteContext is in pipeline.dart (it needs RequestContext, avoiding circular deps).
// =============================================================================

import 'types.dart';

// ---------------------------------------------------------------------------
// AllowedHostPolicy
// ---------------------------------------------------------------------------

/// Per-host allowlist entry inside a [RouteManifest].
class AllowedHostPolicy {
  final String host;
  final Set<String> schemes;
  final Set<String> methods;
  final Set<String> purposes;
  final Duration? ttl;

  AllowedHostPolicy({
    required this.host,
    this.schemes = const {'https', 'wss', 'udp', 'grpc', 'http', 'ws'},
    this.methods = const {
      'GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'QUERY', 'UDP', 'RPC'
    },
    this.purposes = const {
      'private', 'public', 'media', 'socket', 'duplex', 'udp', 'rpc'
    },
    this.ttl,
  });

  bool allows(Uri uri, {required String method, required String purpose}) =>
      uri.host == host &&
      schemes.contains(uri.scheme) &&
      methods.contains(method) &&
      purposes.contains(purpose);
}

// ---------------------------------------------------------------------------
// SessionPolicy
// ---------------------------------------------------------------------------

class SessionPolicy {
  final SessionPolicyScope scope;
  final Duration? ttl;
  final bool allowPublicApis;
  final bool allowMedia;
  final bool allowSocket;
  final bool allowDuplex;
  final bool allowUdp;
  final bool allowRpc;
  final bool requireRevalidateOnHostChange;

  const SessionPolicy({
    required this.scope,
    this.ttl,
    this.allowPublicApis = false,
    this.allowMedia = false,
    this.allowSocket = false,
    this.allowDuplex = false,
    this.allowUdp = false,
    this.allowRpc = false,
    this.requireRevalidateOnHostChange = true,
  });
}

// ---------------------------------------------------------------------------
// RouteManifest
// ---------------------------------------------------------------------------

/// Server-issued manifest — tells the client which base URL to use
/// for each transport kind, with optional expiry and signature.
class RouteManifest {
  final Uri httpBase;
  final Uri? websocketBase;
  final Uri? duplexBase;
  final Uri? mediaBase;
  final Uri? udpBase;
  final Uri? rpcBase;
  final String? manifestId;
  final DateTime? expiresAt;
  final SessionPolicy sessionPolicy;
  final List<AllowedHostPolicy> allowedHosts;
  final Map<String, dynamic> hints;
  final String? signature;
  final String? serverDelegatedSignature;

  RouteManifest({
    required this.httpBase,
    this.websocketBase,
    this.duplexBase,
    this.mediaBase,
    this.udpBase,
    this.rpcBase,
    this.manifestId,
    this.expiresAt,
    this.sessionPolicy =
        const SessionPolicy(scope: SessionPolicyScope.sessionOnly),
    this.allowedHosts = const [],
    this.hints = const {},
    this.signature,
    this.serverDelegatedSignature,
  });

  bool isExpired() =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  bool allows(Uri uri, {required String method, required String purpose}) =>
      allowedHosts.any((p) => p.allows(uri, method: method, purpose: purpose));
}

// ---------------------------------------------------------------------------
// RouteProvider
// ---------------------------------------------------------------------------

/// Resolves the active [RouteManifest] for a given request context.
/// RouteContext is defined in pipeline.dart.
abstract class RouteProvider {
  Future<RouteManifest?> resolve(dynamic context); // RouteContext
}

/// Always returns the same [RouteManifest].
class StaticRouteProvider implements RouteProvider {
  final RouteManifest manifest;
  StaticRouteProvider(this.manifest);

  @override
  Future<RouteManifest?> resolve(dynamic context) async => manifest;
}
