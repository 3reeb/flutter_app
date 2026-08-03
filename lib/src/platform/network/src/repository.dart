// =============================================================================
// repository.dart — Reactive CRUD, ApiModule, AppLifecycleManager.
// =============================================================================

import 'dart:async';

import 'types.dart';
import 'upload.dart';
import 'pipeline.dart';
import 'realtime.dart';
import 'media.dart';

// ---------------------------------------------------------------------------
// ApiModule — prefixed request helper
// ---------------------------------------------------------------------------

class ApiModule {
  final dynamic client; // ApiClient
  final String prefix;

  const ApiModule(this.client, {this.prefix = ''});

  String _joinPath(String path) {
    if (prefix.isEmpty) return path;
    return path.startsWith('/') ? '$prefix$path' : '$prefix/$path';
  }

  Future<ApiResponse<T>> request<T>({
    required String method,
    required String path,
    required RequestKind kind,
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
    dynamic body,
    JsonFactory<T>? decode,
    Duration? timeout,
  }) {
    return (client as dynamic).request<T>(
      method: method,
      path: _joinPath(path),
      kind: kind,
      query: query,
      headers: headers,
      body: body,
      decode: decode,
      timeout: timeout,
    );
  }
}

// ---------------------------------------------------------------------------
// ReactiveCrudRepository — cache-first CRUD with live push stream
// ---------------------------------------------------------------------------

class ReactiveCrudRepository<T> {
  final ApiModule api;
  final String resourcePath;
  final JsonFactory<T> fromJson;
  final JsonEncoderFn<T> toJson;

  final StreamController<T> _docStream = StreamController<T>.broadcast();
  final StreamController<List<T>> _listStream =
      StreamController<List<T>>.broadcast();

  ReactiveCrudRepository({
    required this.api,
    required this.resourcePath,
    required this.fromJson,
    required this.toJson,
  });

  Stream<T> watch(String id) async* {
    final cacheKey = _docKey(id);
    final cached =
        await (api.client as dynamic).cacheStore.get(cacheKey);
    if (cached != null && !(cached as dynamic).isExpired) {
      final decoded = cached.value is String
          ? await (api.client as dynamic).decodeJson(cached.value)
          : cached.value;
      yield fromJson(decoded);
    }

    try {
      final res = await api.request<T>(
        method: 'GET',
        path: '$resourcePath/$id',
        kind: RequestKind.rest,
        decode: fromJson,
      );
      _docStream.add(res.data);
      yield res.data;
    } catch (e) {
      if (cached == null) rethrow;
    }

    yield* _docStream.stream;
  }

  Future<List<T>> list({Map<String, dynamic> query = const {}}) async {
    final res = await api.request<List<T>>(
      method: 'GET',
      path: resourcePath,
      kind: RequestKind.rest,
      query: query,
      decode: (json) =>
          ((json as List?) ?? const []).map((e) => fromJson(e)).toList(),
    );
    return res.data;
  }

  Future<T> read(String id) async {
    final res = await api.request<T>(
      method: 'GET',
      path: '$resourcePath/$id',
      kind: RequestKind.rest,
      decode: fromJson,
    );
    return res.data;
  }

  Future<T> create(T value) async {
    final res = await api.request<T>(
      method: 'POST',
      path: resourcePath,
      kind: RequestKind.rest,
      body: toJson(value),
      decode: fromJson,
    );
    return res.data;
  }

  Future<T> update(String id, T value) async {
    final res = await api.request<T>(
      method: 'PUT',
      path: '$resourcePath/$id',
      kind: RequestKind.rest,
      body: toJson(value),
      decode: fromJson,
    );
    _docStream.add(res.data);
    return res.data;
  }

  Future<void> remove(String id) async {
    await api.request<dynamic>(
      method: 'DELETE',
      path: '$resourcePath/$id',
      kind: RequestKind.rest,
      decode: (json) => json,
    );
  }

  String _docKey(String id) {
    final uri =
        (api.client as dynamic).config.baseUrl.resolve('$resourcePath/$id');
    return 'GET:$uri:${(api.client as dynamic).config.defaultTrustTier.name}:null';
  }

  void dispose() {
    _docStream.close();
    _listStream.close();
  }
}

// ---------------------------------------------------------------------------
// AppLifecycleManager
// ---------------------------------------------------------------------------

class AppLifecycleManager {
  final List<RealtimeClient> _realtimeClients = [];
  final List<UdpConnection> _udpConnections = [];

  void registerRealtimeClient(RealtimeClient client) =>
      _realtimeClients.add(client);
  void registerUdpConnection(UdpConnection udp) => _udpConnections.add(udp);

  Future<void> onAppPaused() async {
    for (final c in _realtimeClients) {
      await c.close();
    }
  }

  Future<void> onAppResumed() async {
    for (final c in _realtimeClients) {
      await c.connect();
    }
  }

  Future<void> dispose() async {
    for (final u in _udpConnections) {
      await u.close();
    }
    _udpConnections.clear();
    _realtimeClients.clear();
  }
}
