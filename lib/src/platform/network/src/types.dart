// =============================================================================
// types.dart — Core enumerations, constants, and primitive types.
// No imports from other src/ files. Safe for all targets.
// =============================================================================

/// HTTP header name constants (no dart:io dependency).
class HttpHeaders {
  static const String acceptHeader = 'accept';
  static const String authorizationHeader = 'authorization';
  static const String contentTypeHeader = 'content-type';
  static const String contentLengthHeader = 'content-length';
  static const String rangeHeader = 'range';
  static const String userAgentHeader = 'user-agent';
  HttpHeaders._();
}

// ---------------------------------------------------------------------------
// File abstraction
// ---------------------------------------------------------------------------

enum QuantumFileMode { append, writeOnly }

/// Abstract write sink for streaming data into a [QuantumFile].
abstract class QuantumFileSink {
  void add(List<int> data);
  Future<void> flush(); // BUG FIX: was missing, caused crash in ResumableTransferManager
  Future<void> close();
}

/// Cross-platform file abstraction.
/// Native → io.File-backed. Web → in-memory Uint8List.
abstract class QuantumFile {
  String get path;
  Stream<List<int>> openRead();
  QuantumFileSink openWrite({QuantumFileMode mode = QuantumFileMode.writeOnly});
  int lengthSync();
}

// ---------------------------------------------------------------------------
// Enumerations
// ---------------------------------------------------------------------------

/// Trust tier for outgoing requests — drives auth and policy checks.
enum ApiTrustTier { privateSourceOfTruth, authenticatedPublic, public }

/// Caching strategy for GET requests.
enum CachePolicy {
  networkOnly,
  cacheFirst,
  networkFirst,
  staleWhileRevalidate,
  cacheOnly,
}

/// Intent of a network call — drives URL-base resolution and manifest lookup.
enum RequestKind { rest, query, batch, stream, socket, duplex, media, udp, rpc }

/// Direction of a resumable transfer.
enum TransferDirection { upload, download }

/// Media track content type.
enum MediaTrackType { audio, video, image }

/// Quality-switch animation mode.
enum MediaSwitchMode { seamless, buffered, immediate }

/// Session lifetime scope.
enum SessionPolicyScope { requestOnly, sessionOnly, ttl, untilRevoked }

/// Encryption mode for [CryptoPolicy].
enum EncryptionMode { none, external, hardware }

/// UDP packet content type for [UdpMediaPacket].
enum UdpPacketType { appData, audio, video, ping }

// ---------------------------------------------------------------------------
// ApiClientConfig
// ---------------------------------------------------------------------------

/// Immutable configuration for an [ApiClient] instance.
class ApiClientConfig {
  final Uri baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Map<String, String> defaultHeaders;
  final bool enableLogging;
  final String? userAgent;
  final ApiTrustTier defaultTrustTier;
  final int maxRetries;
  final List<String>? allowedCertFingerprintsSha256;

  const ApiClientConfig({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 20),
    this.receiveTimeout = const Duration(seconds: 30),
    this.defaultHeaders = const {},
    this.enableLogging = false,
    this.userAgent,
    this.defaultTrustTier = ApiTrustTier.privateSourceOfTruth,
    this.maxRetries = 3,
    this.allowedCertFingerprintsSha256,
  });
}
