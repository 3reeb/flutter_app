import 'package:flutter/foundation.dart';
import '../../platform/quantum_native_bridge.dart';
import '../../foundation/quantum_async.dart';
// ────────────────────────────────────────────────────────────────────────────
// PRACTICAL FILE ACCESS MODELS
// ────────────────────────────────────────────────────────────────────────────

class PickedDocument {
  final String path;
  final String name;

  const PickedDocument({
    required this.path,
    required this.name,
  });

  factory PickedDocument.fromMap(Map<String, dynamic> map) {
    return PickedDocument(
      path: map['path'] as String,
      name: map['name'] as String,
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// CODECS & BRIDGES
// ────────────────────────────────────────────────────────────────────────────

class _VoidDocsCodec extends QLChannelCodec<void, List<PickedDocument>> {
  const _VoidDocsCodec();
  @override dynamic encode(void args) => null;
  @override List<PickedDocument> decode(dynamic data) {
    if (data == null) return [];
    return (data as List).map((e) => PickedDocument.fromMap(Map<String, dynamic>.from(e))).toList();
  }
}

class _PickDocumentsBridge extends QLMethodBridge<void, List<PickedDocument>> {
  @override String get channelName => 'quantum_files/pick';
  @override QLChannelCodec<void, List<PickedDocument>> get codec => const _VoidDocsCodec();
}

class _ReadRawCodec extends QLChannelCodec<String, Uint8List> {
  const _ReadRawCodec();
  @override dynamic encode(String args) => args;
  @override Uint8List decode(dynamic data) => data as Uint8List;
}

class _ReadBytesBridge extends QLMethodBridge<String, Uint8List> {
  @override String get channelName => 'quantum_files/read';
  @override QLChannelCodec<String, Uint8List> get codec => const _ReadRawCodec();
}

class _WriteRawCodec extends QLChannelCodec<Map<String, dynamic>, bool> {
  const _WriteRawCodec();
  @override dynamic encode(Map<String, dynamic> args) => args;
  @override bool decode(dynamic data) => data == true;
}

class _WriteBytesBridge extends QLMethodBridge<Map<String, dynamic>, bool> {
  @override String get channelName => 'quantum_files/write';
  @override QLChannelCodec<Map<String, dynamic>, bool> get codec => const _WriteRawCodec();
}

// ────────────────────────────────────────────────────────────────────────────
// PRACTICAL API FACADE
// ────────────────────────────────────────────────────────────────────────────

class QuantumFileAccess {
  static final QuantumFileAccess instance = QuantumFileAccess._();

  QuantumFileAccess._() {
    QLNativeBridgeRegistry.instance.register('quantum_files/pick', _pick);
    QLNativeBridgeRegistry.instance.register('quantum_files/read', _read);
    QLNativeBridgeRegistry.instance.register('quantum_files/write', _write);
  }

  final _pick = _PickDocumentsBridge();
  final _read = _ReadBytesBridge();
  final _write = _WriteBytesBridge();

  /// Launches the native document picker to select files (useful for attaching PDFs in chat/email).
  QLAsyncSignal<List<PickedDocument>> pickDocuments() {
    return _pick(null);
  }

  /// Reads a file directly from a path.
  QLAsyncSignal<Uint8List> readBytes(String path) {
    return _read(path);
  }

  /// Writes raw bytes to a file path (useful for saving downloaded files).
  QLAsyncSignal<bool> writeBytes(String path, Uint8List bytes) {
    return _write({'path': path, 'bytes': bytes});
  }
}
