// ════════════════════════════════════════════════════════════════════════════
// downloader.dart
//
// Small cross-platform download helpers used by the SDUI studio.
// ════════════════════════════════════════════════════════════════════════════

import 'dart:typed_data';
import 'package:quantum_layout/src/runtime/downloader_io.dart'
    if (dart.library.html) 'package:quantum_layout/src/runtime/downloader_web.dart' as impl;

Future<String> downloadText(
  String text,
  String filename, {
  String? mimeType,
}) {
  return impl.downloadText(text, filename, mimeType: mimeType);
}

Future<void> downloadImage(
  Uint8List bytes,
  String filename,
) {
  return impl.downloadImage(bytes, filename);
}
