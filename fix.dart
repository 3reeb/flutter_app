import 'dart:io';
import 'dart:convert';

void fixDebugPaths(dynamic node, String newRoot) {
  if (node is Map<String, dynamic>) {
    if (node.containsKey('debugPath') && node['debugPath'] is String) {
      String debugPath = node['debugPath'];
      node['debugPath'] = debugPath.replaceFirst(RegExp(r'^[^.]+'), newRoot);
    }
    for (var value in node.values) {
      fixDebugPaths(value, newRoot);
    }
  } else if (node is List) {
    for (var item in node) {
      fixDebugPaths(item, newRoot);
    }
  }
}

void main() {
  final dir = Directory(r'C:\flutter\resposive layout\lib\test\generated\sdui_json_runtime_behavior_test\cases');
  final files = dir.listSync(recursive: true).where((e) => e is File && e.path.endsWith('.json')).cast<File>();
  
  for (var file in files) {
    final content = file.readAsStringSync();
    try {
      final json = jsonDecode(content);
      if (json is Map<String, dynamic> && json.containsKey('expected')) {
        final expected = json['expected'];
        if (expected is Map<String, dynamic> && expected.containsKey('props')) {
          final props = expected['props'];
          if (props is Map<String, dynamic> && props.containsKey('name')) {
            final name = props['name'];
            if (name is String) {
              fixDebugPaths(expected, name);
              
              const encoder = JsonEncoder.withIndent('  ');
              final newContent = encoder.convert(json);
              file.writeAsStringSync(newContent);
              print('Updated ${file.path}');
            }
          }
        }
      }
    } catch (e) {
      print('Error parsing ${file.path}: $e');
    }
  }
}
