// =============================================================================
// exceptions.dart — Network stack exception hierarchy.
// No platform-specific imports.
// =============================================================================

/// Thrown when an HTTP response returns a 4xx/5xx status.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Uri? uri;
  final dynamic body;
  final String? code;

  const ApiException({
    required this.message,
    this.statusCode,
    this.uri,
    this.body,
    this.code,
  });

  @override
  String toString() =>
      'ApiException(${code ?? ''}${statusCode != null ? ' $statusCode' : ''} $message${uri != null ? ' $uri' : ''})';
}

/// Thrown when a request is blocked by a [RouteManifest] policy.
class PolicyViolation implements Exception {
  final String message;
  final Uri? uri;
  const PolicyViolation(this.message, {this.uri});

  @override
  String toString() =>
      'PolicyViolation($message${uri == null ? '' : ' uri=$uri'})';
}

/// Thrown when a response is missing its expected integrity signature.
class IntegrityViolation implements Exception {
  final String message;
  final Uri? uri;
  const IntegrityViolation(this.message, {this.uri});

  @override
  String toString() =>
      'IntegrityViolation($message${uri == null ? '' : ' uri=$uri'})';
}

/// Sentinel exception used internally by [OAuthRefreshPolicy] to signal that
/// a request should be retried after a token refresh.
class RequestRetryException implements Exception {
  const RequestRetryException();
}

/// High-level cloud adapter exception for use in OmniCloud domain code.
class OmniCloudException implements Exception {
  final String code;
  final String message;
  final dynamic originalError;

  const OmniCloudException(this.code, this.message, [this.originalError]);

  @override
  String toString() => 'OmniCloudException($code): $message';
}
