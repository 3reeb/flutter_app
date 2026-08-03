// =============================================================================
// pipeline.dart — Request pipeline: context, policies, routing context,
//                 retry engine, coalescing, and request merging.
//
// BUG FIX: RequestPipeline.policies is now a MUTABLE List (was const [] which
// caused UnsupportedError when ApiClient added OfflineMutationPolicy).
// =============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart' as crypto;

import 'types.dart';
import 'exceptions.dart';
import 'session.dart';
import 'routing.dart';
import 'upload.dart';

// ---------------------------------------------------------------------------
// RequestContext
// ---------------------------------------------------------------------------

/// Immutable snapshot of all parameters for one outgoing request.
/// Policies transform it via [copyWith].
class RequestContext {
  final String method;
  final Uri uri;
  final RequestKind kind;
  final ApiTrustTier trustTier;
  final Map<String, String> headers;
  final dynamic body;
  final CachePolicy cachePolicy;
  final Duration timeout;
  final String? idempotencyKey;
  final String? mergeKey;
  final bool requireIntegrityCheck;
  final RouteManifest? activeManifest;

  const RequestContext({
    required this.method,
    required this.uri,
    required this.kind,
    required this.trustTier,
    required this.headers,
    required this.body,
    required this.cachePolicy,
    required this.timeout,
    this.idempotencyKey,
    this.mergeKey,
    this.requireIntegrityCheck = false,
    this.activeManifest,
  });

  RequestContext copyWith({
    String? method,
    Uri? uri,
    RequestKind? kind,
    ApiTrustTier? trustTier,
    Map<String, String>? headers,
    dynamic body,
    CachePolicy? cachePolicy,
    Duration? timeout,
    String? idempotencyKey,
    String? mergeKey,
    bool? requireIntegrityCheck,
    RouteManifest? activeManifest,
  }) =>
      RequestContext(
        method: method ?? this.method,
        uri: uri ?? this.uri,
        kind: kind ?? this.kind,
        trustTier: trustTier ?? this.trustTier,
        headers: headers ?? this.headers,
        body: body ?? this.body,
        cachePolicy: cachePolicy ?? this.cachePolicy,
        timeout: timeout ?? this.timeout,
        idempotencyKey: idempotencyKey ?? this.idempotencyKey,
        mergeKey: mergeKey ?? this.mergeKey,
        requireIntegrityCheck:
            requireIntegrityCheck ?? this.requireIntegrityCheck,
        activeManifest: activeManifest ?? this.activeManifest,
      );
}

// ---------------------------------------------------------------------------
// RouteContext (here to avoid circular dep: routing.dart ↔ pipeline.dart)
// ---------------------------------------------------------------------------

class RouteContext {
  final RequestContext request;
  final RouteManifest? manifest;
  final String purpose;
  RouteContext({required this.request, required this.purpose, this.manifest});
}

// ---------------------------------------------------------------------------
// RequestPolicy
// ---------------------------------------------------------------------------

abstract class RequestPolicy {
  FutureOr<RequestContext> onRequest(RequestContext context);
  FutureOr<ApiResponse<dynamic>> onResponse(
      RequestContext context, ApiResponse<dynamic> response);
  FutureOr<void> onError(
      RequestContext context, Object error, StackTrace stackTrace);
}

abstract class AdvancedRequestPolicy extends RequestPolicy {
  Future<bool> shouldRetry(
      RequestContext context, ApiResponse<dynamic>? response, Object? error);
}

// ---------------------------------------------------------------------------
// Built-in Policies
// ---------------------------------------------------------------------------

class HeaderPolicy extends RequestPolicy {
  final Map<String, String> headers;
  HeaderPolicy(this.headers);

  @override
  FutureOr<RequestContext> onRequest(RequestContext context) =>
      context.copyWith(headers: {...context.headers, ...headers});

  @override
  FutureOr<ApiResponse<dynamic>> onResponse(
          RequestContext c, ApiResponse<dynamic> r) =>
      r;

  @override
  FutureOr<void> onError(RequestContext c, Object e, StackTrace s) {}
}

class ServerApprovedDelegationPolicy extends RequestPolicy {
  @override
  FutureOr<RequestContext> onRequest(RequestContext context) {
    final sig = context.activeManifest?.serverDelegatedSignature;
    if (context.trustTier == ApiTrustTier.authenticatedPublic && sig != null) {
      return context.copyWith(headers: {
        ...context.headers,
        'X-Server-Delegated-Signature': sig,
      });
    }
    return context;
  }

  @override
  FutureOr<ApiResponse<dynamic>> onResponse(
          RequestContext c, ApiResponse<dynamic> r) =>
      r;

  @override
  FutureOr<void> onError(RequestContext c, Object e, StackTrace s) {}
}

/// Queues failed mutations for offline replay.
/// [isNetworkError] is platform-supplied: native checks SocketException/IOException,
/// web checks http.ClientException. Falls back to message-string heuristic.
class OfflineMutationPolicy extends RequestPolicy {
  final dynamic syncManager; // OfflineQueueManager (dynamic to avoid circular)
  final bool bypass;
  final bool Function(Object)? isNetworkError;

  OfflineMutationPolicy(this.syncManager,
      {this.bypass = false, this.isNetworkError});

  bool _isNetError(Object e) {
    if (isNetworkError != null) return isNetworkError!(e);
    final msg = e.toString().toLowerCase();
    return msg.contains('socket') ||
        msg.contains('network') ||
        msg.contains('connection refused') ||
        msg.contains('unreachable') ||
        msg.contains('clientexception') ||
        msg.contains('failed host lookup');
  }

  @override
  FutureOr<RequestContext> onRequest(RequestContext context) => context;

  @override
  FutureOr<ApiResponse<dynamic>> onResponse(
          RequestContext c, ApiResponse<dynamic> r) =>
      r;

  @override
  FutureOr<void> onError(
      RequestContext context, Object error, StackTrace stackTrace) async {
    if (bypass) return;
    if (_isNetError(error) &&
        const {'POST', 'PUT', 'PATCH', 'DELETE'}.contains(context.method)) {
      await (syncManager as dynamic).enqueue(context);
      throw ApiException(
        message: 'Offline. Mutation queued locally.',
        statusCode: 0,
        uri: context.uri,
      );
    }
  }
}

/// Proactive OAuth token refresh + 401/403 retry.
class OAuthRefreshPolicy extends AdvancedRequestPolicy {
  final AuthProvider auth;
  final Future<void> Function() onRefreshRequired;
  bool _isRefreshing = false;
  Future<void>? _refreshFuture;

  OAuthRefreshPolicy({required this.auth, required this.onRefreshRequired});

  @override
  FutureOr<RequestContext> onRequest(RequestContext context) async {
    if (_isRefreshing && _refreshFuture != null) await _refreshFuture;
    var session = await auth.getSession();
    if (session != null && session.isExpired) {
      if (!_isRefreshing) {
        _isRefreshing = true;
        _refreshFuture = onRefreshRequired().whenComplete(() {
          _isRefreshing = false;
          _refreshFuture = null;
        });
      }
      await _refreshFuture;
      session = await auth.getSession();
    }
    final token = session?.accessToken;
    final deviceId = session?.deviceId;
    if (token != null && token.isNotEmpty) {
      return context.copyWith(headers: {
        ...context.headers,
        'authorization': 'Bearer $token',
        if (deviceId != null) 'X-Device-Id': deviceId,
      });
    }
    return context;
  }

  @override
  FutureOr<ApiResponse<dynamic>> onResponse(
      RequestContext context, ApiResponse<dynamic> response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const RequestRetryException();
    }
    return response;
  }

  @override
  FutureOr<void> onError(RequestContext c, Object e, StackTrace s) {}

  @override
  Future<bool> shouldRetry(RequestContext context,
      ApiResponse<dynamic>? response, Object? error) async {
    final is401 = response?.statusCode == 401 || response?.statusCode == 403;
    final isRetry = error is RequestRetryException;
    final isApiAuth = error is ApiException &&
        (error.statusCode == 401 || error.statusCode == 403);
    if (is401 || isRetry || isApiAuth) {
      if (!_isRefreshing) {
        _isRefreshing = true;
        _refreshFuture = onRefreshRequired().whenComplete(() {
          _isRefreshing = false;
          _refreshFuture = null;
        });
      }
      await _refreshFuture;
      return true;
    }
    return false;
  }
}

class HmacSigningPolicy extends RequestPolicy {
  final String secretKey;
  HmacSigningPolicy(this.secretKey);

  @override
  FutureOr<RequestContext> onRequest(RequestContext context) {
    final ts = DateTime.now().millisecondsSinceEpoch.toString();
    final nonce = DateTime.now().microsecondsSinceEpoch.toString();
    final bodyStr = context.body == null
        ? ''
        : context.body is String
            ? context.body as String
            : jsonEncode(context.body);
    final payload = '${context.method}:${context.uri.path}:$ts:$nonce:$bodyStr';
    return context.copyWith(headers: {
      ...context.headers,
      'X-Signature-Timestamp': ts,
      'X-Signature-Nonce': nonce,
      'X-Signature': _hmacSha256(secretKey, payload),
    });
  }

  @override
  FutureOr<ApiResponse<dynamic>> onResponse(
          RequestContext c, ApiResponse<dynamic> r) =>
      r;

  @override
  FutureOr<void> onError(RequestContext c, Object e, StackTrace s) {}
}

class RateLimiterPolicy extends RequestPolicy {
  final int maxTokens;
  final Duration refillInterval;
  int _tokens;
  DateTime _lastRefill;

  RateLimiterPolicy({
    this.maxTokens = 50,
    this.refillInterval = const Duration(seconds: 1),
  })  : _tokens = maxTokens,
        _lastRefill = DateTime.now();

  void _refill() {
    final now = DateTime.now();
    if (now.difference(_lastRefill) >= refillInterval) {
      _tokens = maxTokens;
      _lastRefill = now;
    }
  }

  @override
  FutureOr<RequestContext> onRequest(RequestContext context) async {
    _refill();
    if (_tokens <= 0) {
      await Future<void>.delayed(refillInterval);
      _refill();
    }
    _tokens--;
    return context;
  }

  @override
  FutureOr<ApiResponse<dynamic>> onResponse(
          RequestContext c, ApiResponse<dynamic> r) =>
      r;

  @override
  FutureOr<void> onError(RequestContext c, Object e, StackTrace s) {}
}

class TraceparentPolicy extends RequestPolicy {
  @override
  FutureOr<RequestContext> onRequest(RequestContext context) {
    final rand = Random.secure();
    final seed =
        '${DateTime.now().microsecondsSinceEpoch}_${rand.nextInt(1 << 32)}';
    final traceId = _sha256Hex(utf8.encode('$seed-trace')).substring(0, 32);
    final spanId = _sha256Hex(utf8.encode('$seed-span')).substring(0, 16);
    return context.copyWith(headers: {
      ...context.headers,
      'traceparent': '00-$traceId-$spanId-01',
    });
  }

  @override
  FutureOr<ApiResponse<dynamic>> onResponse(
          RequestContext c, ApiResponse<dynamic> r) =>
      r;

  @override
  FutureOr<void> onError(RequestContext c, Object e, StackTrace s) {}
}

// ---------------------------------------------------------------------------
// RequestPipeline — BUG FIX: policies is now a MUTABLE List
// ---------------------------------------------------------------------------

class RequestPipeline {
  /// Mutable policy list — safe to add policies after construction.
  final List<RequestPolicy> policies;

  RequestPipeline({List<RequestPolicy>? policies})
      : policies = policies != null ? List<RequestPolicy>.of(policies) : [];

  Future<ApiResponse<dynamic>> execute(
    RequestContext initialContext,
    int maxRetries,
    Future<ApiResponse<dynamic>> Function(RequestContext c) action,
  ) async {
    var attempts = 0;
    while (true) {
      attempts++;
      var ctx = initialContext;
      try {
        for (final p in policies) {
          ctx = await p.onRequest(ctx);
        }
        var response = await action(ctx);
        for (final p in policies.reversed) {
          response = await p.onResponse(ctx, response);
        }
        return response;
      } catch (e, s) {
        var willRetry = false;
        for (final p in policies) {
          if (p is AdvancedRequestPolicy) {
            if (await p.shouldRetry(ctx, null, e)) willRetry = true;
          }
        }
        if (!willRetry && _isTransient(e)) willRetry = true;
        if (!willRetry || attempts > maxRetries) {
          for (final p in policies.reversed) {
            await p.onError(ctx, e, s);
          }
          rethrow;
        }
        await Future<void>.delayed(
            Duration(milliseconds: 200 * pow(2, attempts).toInt()));
      }
    }
  }

  static bool _isTransient(Object e) {
    if (e is ApiException) {
      final c = e.statusCode;
      return c == null || c >= 500 || c == 429;
    }
    final m = e.toString().toLowerCase();
    return m.contains('timeout') ||
        m.contains('socket') ||
        m.contains('connection');
  }
}

// ---------------------------------------------------------------------------
// CoalescingPolicy — deduplicates in-flight requests
// ---------------------------------------------------------------------------

class CoalescingPolicy {
  final Map<String, Completer<ApiResponse<dynamic>>> _inFlight = {};

  Future<ApiResponse<dynamic>> coalesce(
      String key, Future<ApiResponse<dynamic>> Function() action) {
    final existing = _inFlight[key];
    if (existing != null) return existing.future;
    final completer = Completer<ApiResponse<dynamic>>();
    _inFlight[key] = completer;
    () async {
      try {
        final result = await action();
        if (!completer.isCompleted) completer.complete(result);
      } catch (e, s) {
        if (!completer.isCompleted) completer.completeError(e, s);
      } finally {
        _inFlight.remove(key);
      }
    }();
    return completer.future;
  }
}

// ---------------------------------------------------------------------------
// RequestMerger — fans a single response out to multiple waiters
// ---------------------------------------------------------------------------

class RequestMerger {
  final Map<String, Future<ApiResponse<dynamic>>> _slots = {};

  Future<ApiResponse<dynamic>> merge(
      String key, Future<ApiResponse<dynamic>> Function() action) {
    return _slots.putIfAbsent(key, () {
      final f = action();
      f.whenComplete(() => _slots.remove(key));
      return f;
    });
  }
}

// ---------------------------------------------------------------------------
// Internal crypto helpers
// ---------------------------------------------------------------------------

String _sha256Hex(List<int> input) => crypto.sha256.convert(input).toString();

String _hmacSha256(String key, String message) =>
    crypto.Hmac(crypto.sha256, utf8.encode(key))
        .convert(utf8.encode(message))
        .toString();
