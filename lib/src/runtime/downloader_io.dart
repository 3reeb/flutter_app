/*
 * ============================================================================
 * File: downloader_io.dart
 * 
 * Description:
 * Provides file downloading capabilities for dart:io environments (mobile/desktop).
 * It writes text and image data directly to the system's temporary directory,
 * making it suitable for local file persistence outside of the web browser.
 * 
 * Key Components:
 * - downloadText: Asynchronously saves a given string to a temporary file.
 * - downloadImage: Asynchronously saves a byte array (image) to a temporary file.
 * 
 * Dependencies/Relationships:
 * Relies on dart:io for file system operations and lutter/foundation.dart 
 * for debug logging. Functions as the I/O specific counterpart to downloader_web.dart.
 * 
 * Notes:
 * This implementation is strictly for non-web platforms. It uses Directory.systemTemp
 * which may require specific permissions depending on the host OS.
 * ============================================================================
 */
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
