import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

Future<String> downloadText(String content, String filename,
    {String mimeType = 'application/json'}) async {
  final dir = Directory.systemTemp.createTempSync('quantum_export_');
  final file = File('${dir.path}/$filename');
  await file.writeAsString(content, flush: true);
  if (kDebugMode) {
    debugPrint('Saved text export to: ${file.path}');
  }
  return file.path;
}

Future<String> downloadImage(Uint8List bytes, String filename) async {
  final dir = Directory.systemTemp.createTempSync('quantum_export_');
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes, flush: true);
  if (kDebugMode) {
    debugPrint('Saved image export to: ${file.path}');
  }
  return file.path;
}
