import 'dart:convert';
import 'dart:io';

import 'quantum_http_transport.dart';

QuantumHttpTransport createQuantumHttpTransport() => _IoQuantumHttpTransport();

class _IoQuantumHttpTransport implements QuantumHttpTransport {
  final HttpClient _client = HttpClient();

  @override
  Future<QuantumHttpRequest> openUrl(String method, Uri uri) async {
    final req = await _client.openUrl(method, uri);
    return _IoQuantumHttpRequest(req);
  }

  @override
  void close({bool force = false}) => _client.close(force: force);
}

class _IoQuantumHttpRequest implements QuantumHttpRequest {
  final HttpClientRequest _req;
  final Map<String, String> _headers = <String, String>{};

  _IoQuantumHttpRequest(this._req);

  @override
  Map<String, String> get headers => _headers;

  @override
  void add(List<int> data) => _req.add(data);

  @override
  Future<QuantumHttpResponse> close() async {
    // Apply our map headers to the actual dart:io request right before closing
    _headers.forEach((key, value) {
      _req.headers.set(key, value);
    });

    final res = await _req.close();
    return _IoQuantumHttpResponse(res);
  }
}

class _IoQuantumHttpResponse implements QuantumHttpResponse {
  final HttpClientResponse _res;
  Map<String, String>? _cachedHeaders;

  _IoQuantumHttpResponse(this._res);

  @override
  int get statusCode => _res.statusCode;

  @override
  Map<String, String> get headers {
    if (_cachedHeaders != null) return _cachedHeaders!;

    final map = <String, String>{};
    // Convert dart:io HttpHeaders to standard Map<String, String>
    _res.headers.forEach((name, values) {
      map[name] = values.join(',');
    });

    _cachedHeaders = map;
    return map;
  }

  @override
  Future<String> text() => utf8.decodeStream(_res);
}
