import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart'; // Import this separately for BrowserClient

import 'quantum_http_transport.dart';
QuantumHttpTransport createQuantumHttpTransport() => _WebQuantumHttpTransport();

class _WebQuantumHttpTransport implements QuantumHttpTransport {
  // Use BrowserClient directly
  final BrowserClient _client = BrowserClient();

  @override
  Future<QuantumHttpRequest> openUrl(String method, Uri uri) async {
    return _WebQuantumHttpRequest(_client, method, uri);
  }

  @override
  void close({bool force = false}) => _client.close();
}

class _WebQuantumHttpRequest implements QuantumHttpRequest {
  final BrowserClient _client;
  final String method;
  final Uri uri;
  final Map<String, String> _headers = <String, String>{};
  final List<int> _body = <int>[];

  _WebQuantumHttpRequest(this._client, this.method, this.uri);

  @override
  Map<String, String> get headers => _headers;

  @override
  void add(List<int> data) => _body.addAll(data);

  @override
  Future<QuantumHttpResponse> close() async {
    // Changed BaseRequest to http.Request (which is a concrete class)
    final request = http.Request(method, uri)
      ..headers.addAll(_headers)
      ..bodyBytes = Uint8List.fromList(_body);

    final response = await _client.send(request);

    return _WebQuantumHttpResponse(response);
  }
}

class _WebQuantumHttpResponse implements QuantumHttpResponse {
  // StreamedResponse is now properly resolved from package:http/http.dart
  final http.StreamedResponse _res;

  _WebQuantumHttpResponse(this._res);

  @override
  int get statusCode => _res.statusCode;

  @override
  Map<String, String> get headers => _res.headers;

  @override
  Future<String> text() async => utf8.decode(await _res.stream.toBytes());
}
