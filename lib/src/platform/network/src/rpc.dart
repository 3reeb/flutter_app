// =============================================================================
// rpc.dart — QueryEngine, BatchManager, BinaryRpcClient.
// =============================================================================

import 'dart:async';
import 'dart:typed_data';

import 'upload.dart'; // ApiResponse, JsonFactory

// ---------------------------------------------------------------------------
// QueryEngine
// ---------------------------------------------------------------------------

class QueryRequest<T> {
  final String name;
  final Map<String, dynamic> variables;
  final String contentType;
  final String accept;
  final JsonFactory<T>? decode;

  const QueryRequest({
    required this.name,
    this.variables = const {},
    this.contentType = 'application/json; charset=utf-8',
    this.accept = 'application/json',
    this.decode,
  });
}

class QueryEngine {
  final dynamic client; // ApiClient
  QueryEngine(this.client);

  Future<ApiResponse<T>> query<T>(
    String path, {
    required QueryRequest<T> request,
    Map<String, String> headers = const {},
    Map<String, dynamic> query = const {},
    Duration? timeout,
    dynamic trustTier,
    String? mergeKey,
    dynamic cachePolicy,
  }) {
    return (client as dynamic).query<T>(
      path,
      body: {'query': request.name, 'variables': request.variables},
      query: query,
      headers: {
        ...headers,
        'content-type': request.contentType,
        'accept': request.accept,
      },
      decode: request.decode,
      timeout: timeout,
      trustTier: trustTier,
      mergeKey: mergeKey,
      cachePolicy: cachePolicy,
    );
  }
}

// ---------------------------------------------------------------------------
// Batch HTTP
// ---------------------------------------------------------------------------

class BatchRequestItem {
  final String id;
  final String method;
  final String path;
  final Map<String, dynamic> query;
  final dynamic body;
  final Map<String, String> headers;

  const BatchRequestItem({
    required this.id,
    required this.method,
    required this.path,
    this.query = const {},
    this.body,
    this.headers = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'method': method,
        'path': path,
        'query': query,
        'body': body,
        'headers': headers,
      };
}

class BatchResultItem {
  final String id;
  final int statusCode;
  final dynamic body;
  final Map<String, String> headers;

  const BatchResultItem({
    required this.id,
    required this.statusCode,
    required this.body,
    required this.headers,
  });

  factory BatchResultItem.fromJson(dynamic json) {
    final m = (json as Map).cast<String, dynamic>();
    return BatchResultItem(
      id: m['id']?.toString() ?? '',
      statusCode: (m['statusCode'] as num?)?.toInt() ?? 200,
      body: m['body'],
      headers: Map<String, String>.from((m['headers'] ?? const {}) as Map),
    );
  }
}

class BatchResponse {
  final List<BatchResultItem> items;
  const BatchResponse(this.items);

  factory BatchResponse.fromJson(dynamic json) {
    final m = (json as Map).cast<String, dynamic>();
    return BatchResponse(
      (m['items'] as List? ?? const []).map(BatchResultItem.fromJson).toList(),
    );
  }
}

class BatchManager {
  final dynamic client; // ApiClient
  final String batchPath;
  BatchManager({required this.client, this.batchPath = '/batch'});

  Future<BatchResponse> send(List<BatchRequestItem> items) async {
    final res = await (client as dynamic).post<BatchResponse>(
      batchPath,
      body: {'items': items.map((e) => e.toJson()).toList()},
      decode: (json) => BatchResponse.fromJson(json),
    );
    return res.data;
  }
}

// ---------------------------------------------------------------------------
// Binary RPC
// ---------------------------------------------------------------------------

abstract class RpcTransport {
  Future<Uint8List> call(String method, Uint8List payload);
}

class BinaryRpcClient {
  final RpcTransport transport;
  const BinaryRpcClient(this.transport);

  Future<TResponse> invoke<TRequest, TResponse>(
    String method,
    TRequest request, {
    required Uint8List Function(TRequest) serialize,
    required TResponse Function(Uint8List) deserialize,
  }) async {
    final bytes = serialize(request);
    final responseBytes = await transport.call(method, bytes);
    return deserialize(responseBytes);
  }
}
