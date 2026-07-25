import 'dart:io';
import 'dart:typed_data';

void downloadImage(Uint8List bytes, String filename) async {
  // Save to current directory or fallback to a hardcoded path
  final file = File(filename);
  await file.writeAsBytes(bytes);
  print('Saved to ${file.absolute.path}');
}
