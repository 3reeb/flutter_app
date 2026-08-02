/*
 * ============================================================================
 * File: downloader_web.dart
 * 
 * Description:
 * Provides file downloading capabilities for the web environment. It utilizes
 * HTML5 Blob and object URLs to dynamically generate downloadable files and
 * triggers the browser's download prompt via a hidden anchor element.
 * 
 * Key Components:
 * - downloadText: Creates a Blob from text and triggers a browser download.
 * - downloadImage: Creates an image Blob from bytes and triggers a browser download.
 * 
 * Dependencies/Relationships:
 * Depends on dart:html for DOM manipulation (Blob, Url, AnchorElement). Acts as 
 * the web-specific counterpart to downloader_io.dart.
 * 
 * Notes:
 * Automatically cleans up object URLs and temporary DOM elements after the 
 * download prompt is triggered to prevent memory leaks.
 * ============================================================================
 */
import 'dart:html' as html;
import 'dart:typed_data';
Future<String> downloadText(
  String text,
  String filename, {
  String? mimeType,
}) async {
  final bytes = html.Blob([text], mimeType ?? 'text/plain');
  final url = html.Url.createObjectUrlFromBlob(bytes);
  final anchor = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return filename;
}

Future<void> downloadImage(
  Uint8List bytes,
  String filename,
) async {
  final blob = html.Blob([bytes], 'image/png');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
