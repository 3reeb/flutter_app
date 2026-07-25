import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

Future<String> downloadText(String content, String filename,
    {String mimeType = 'application/json'}) async {
  final bytes = Uint8List.fromList(utf8.encode(content));
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';

  final body = html.document.body ?? html.document.documentElement;
  body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return url;
}

Future<String> downloadImage(Uint8List bytes, String filename) async {
  final blob = html.Blob([bytes], 'image/png');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';

  final body = html.document.body ?? html.document.documentElement;
  body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return url;
}
