// =============================================================================
// upload.dart — Transfer primitives: progress, responses, multipart bodies.
// Imports types.dart for QuantumFile.
// =============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'types.dart';

// ---------------------------------------------------------------------------
// Typedefs
// ---------------------------------------------------------------------------

typedef JsonFactory<T> = T Function(dynamic json);
typedef JsonEncoderFn<T> = dynamic Function(T value);

// ---------------------------------------------------------------------------
// ApiResponse
// ---------------------------------------------------------------------------

/// Typed wrapper around a decoded HTTP response.
class ApiResponse<T> {
  final int statusCode;
  final Map<String, String> headers;
  final T data;
  final Uri uri;

  const ApiResponse({
    required this.statusCode,
    required this.headers,
    required this.data,
    required this.uri,
  });
}

// ---------------------------------------------------------------------------
// StreamProgress
// ---------------------------------------------------------------------------

class StreamProgress {
  final int sentBytes;
  final int? totalBytes;

  const StreamProgress({required this.sentBytes, this.totalBytes});

  double? get ratio => (totalBytes == null || totalBytes == 0)
      ? null
      : sentBytes / totalBytes!;
}

// ---------------------------------------------------------------------------
// UploadFile
// ---------------------------------------------------------------------------

/// A file part for multipart uploads — stream-backed for low memory use.
class UploadFile {
  final String fieldName;
  final String fileName;
  final String contentType;
  final Stream<List<int>> stream;
  final int? length;

  const UploadFile({
    required this.fieldName,
    required this.fileName,
    required this.contentType,
    required this.stream,
    this.length,
  });

  factory UploadFile.fromBytes({
    required String fieldName,
    required String fileName,
    required String contentType,
    required Uint8List bytes,
  }) =>
      UploadFile(
        fieldName: fieldName,
        fileName: fileName,
        contentType: contentType,
        stream: Stream<List<int>>.value(bytes),
        length: bytes.length,
      );

  /// Create from a [QuantumFile] (abstract, platform-concrete at runtime).
  static UploadFile fromQuantumFile({
    required String fieldName,
    required QuantumFile file,
    required String contentType,
    String? fileName,
  }) =>
      UploadFile(
        fieldName: fieldName,
        fileName: fileName ?? _basename(file.path),
        contentType: contentType,
        stream: file.openRead(),
        length: file.lengthSync(),
      );
}

// ---------------------------------------------------------------------------
// MultipartPart (text fields)
// ---------------------------------------------------------------------------

class MultipartPart {
  final String name;
  final String value;
  const MultipartPart(this.name, this.value);
}

// ---------------------------------------------------------------------------
// MultipartRequestBody
// ---------------------------------------------------------------------------

class MultipartRequestBody {
  final List<MultipartPart> fields;
  final List<UploadFile> files;
  final String boundary;

  MultipartRequestBody({
    this.fields = const [],
    this.files = const [],
    String? boundary,
  }) : boundary =
            boundary ?? 'dart-sdk-${DateTime.now().microsecondsSinceEpoch}';

  String get contentType => 'multipart/form-data; boundary=$boundary';

  Stream<List<int>> stream(
      {void Function(StreamProgress progress)? onSendProgress}) async* {
    var sent = 0;
    for (final field in fields) {
      final chunk = utf8.encode(
        '--$boundary\r\nContent-Disposition: form-data; name="${_esc(field.name)}"\r\n\r\n${field.value}\r\n',
      );
      sent += chunk.length;
      onSendProgress?.call(StreamProgress(sentBytes: sent));
      yield chunk;
    }
    for (final file in files) {
      final header = utf8.encode(
        '--$boundary\r\nContent-Disposition: form-data; name="${_esc(file.fieldName)}"; filename="${_esc(file.fileName)}"\r\nContent-Type: ${file.contentType}\r\n\r\n',
      );
      sent += header.length;
      onSendProgress
          ?.call(StreamProgress(sentBytes: sent, totalBytes: file.length));
      yield header;
      await for (final chunk in file.stream) {
        sent += chunk.length;
        onSendProgress
            ?.call(StreamProgress(sentBytes: sent, totalBytes: file.length));
        yield chunk;
      }
      final tail = utf8.encode('\r\n');
      sent += tail.length;
      yield tail;
    }
    yield utf8.encode('--$boundary--\r\n');
  }

  static String _esc(String v) => v.replaceAll('"', r'\"');
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _basename(String path) {
  final n = path.replaceAll('\\', '/');
  final i = n.lastIndexOf('/');
  return i >= 0 ? n.substring(i + 1) : n;
}
