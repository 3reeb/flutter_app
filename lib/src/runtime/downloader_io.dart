import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
Future<String> downloadText(
  String text,
  String filename, {
  String? mimeType,
}) async {
  final file = File('${Directory.systemTemp.path}/$filename');
  await file.parent.create(recursive: true);
  await file.writeAsString(text, flush: true);
  debugPrint('[downloader] saved text to ${file.path} (${mimeType ?? 'text/plain'})');
  return file.path;
}

Future<void> downloadImage(
  Uint8List bytes,
  String filename,
) async {
  final file = File('${Directory.systemTemp.path}/$filename');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes, flush: true);
  debugPrint('[downloader] saved image to ${file.path}');
}
