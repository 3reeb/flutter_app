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
