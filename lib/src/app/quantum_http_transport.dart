import 'quantum_http_transport_io.dart'
    if (dart.library.html) 'quantum_http_transport_web.dart';

abstract class QuantumHttpTransport {
  Future<QuantumHttpRequest> openUrl(String method, Uri uri);
  void close({bool force = false});

  static QuantumHttpTransport platform() => createQuantumHttpTransport();
}

abstract class QuantumHttpRequest {
  dynamic get headers;
  void add(List<int> data);
  Future<QuantumHttpResponse> close();
}

abstract class QuantumHttpResponse {
  int get statusCode;
  Map<String, String> get headers; // Add this if it wasn't there!
  Future<String> text();
}
