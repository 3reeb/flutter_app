// =============================================================================
// transport.dart — Abstract HTTP transport interface.
// Imported by both src/pipeline.dart and each platform transport impl.
// =============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'upload.dart';

// ---------------------------------------------------------------------------
// TransportResponse
// ---------------------------------------------------------------------------

/// Abstraction over a raw HTTP response — stream of bytes with status/headers.
abstract class TransportResponse {
  int get statusCode;
  Map<String, String> get headers;
  Stream<List<int>> get byteStream;

  /// Collect all bytes into a [Uint8List].
  Future<Uint8List> bytes();

  /// Decode body as text. Defaults to UTF-8.
  Future<String> text({Encoding encoding = utf8});
}

// ---------------------------------------------------------------------------
// HttpTransport
// ---------------------------------------------------------------------------

/// Pluggable HTTP transport interface.
///
/// Native impl: IoTransport (dart:io HttpClient with certificate pinning)
/// Web impl:    IoTransport (package:http BrowserClient)
abstract class HttpTransport {
  Future<TransportResponse> send({
    required String method,
    required Uri uri,
    Map<String, String> headers,
    Object? body,
    Duration? timeout,
    void Function(StreamProgress progress)? onSendProgress,
  });

  void dispose();
}
