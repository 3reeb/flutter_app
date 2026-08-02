/*
 * ============================================================================
 * File: quantum_http_transport.dart
 * 
 * Description:
 * Defines the cross-platform abstraction layer for HTTP networking within the 
 * Quantum framework. It uses conditional imports to seamlessly switch between 
 * dart:io for native platforms and dart:html for the web, ensuring a 
 * unified API surface for making network requests.
 * 
 * Key Components:
 * - QuantumHttpTransport: The base factory interface for managing HTTP connections.
 * - QuantumHttpRequest: Interface representing an outgoing HTTP request.
 * - QuantumHttpResponse: Interface representing an incoming HTTP response.
 * 
 * Dependencies/Relationships:
 * Relies on quantum_http_transport_io.dart and quantum_http_transport_web.dart 
 * for platform-specific implementations.
 * 
 * Notes:
 * This abstraction is crucial for framework portability, allowing high-level 
 * components to perform networking tasks without platform-specific dependencies.
 * ============================================================================
 */
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
