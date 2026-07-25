import 'dart:typed_data';

Future<String> downloadText(String content, String filename,
    {String mimeType = 'application/json'}) async {
  throw UnsupportedError('File export is not supported on this platform.');
}

Future<String> downloadImage(Uint8List bytes, String filename) async {
  throw UnsupportedError('Image export is not supported on this platform.');
}
