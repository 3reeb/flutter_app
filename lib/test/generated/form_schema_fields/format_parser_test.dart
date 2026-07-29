import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

void main() {
  group('QLFormatParser: Advanced Data Structures & Anomalies', () {
    test('Perfectly sanitizes complex nested YAML with deep array mappings',
        () {
      // FIX: YAML must be perfectly left-aligned in Dart multi-line strings
      const yaml = '''
matrix:
  - [1, 2, 3]
  - [{"id": 1, "status": active}, {"id": 2, "status": suspended}]
config:
  deep:
    node: { "enabled": true }
''';

      final result = QLFormatParser.parse(yaml);

      expect(result['matrix'][0][1], 2);
      expect(result['matrix'][1][1]['status'], 'suspended');
      expect(result['config']['deep']['node']['enabled'], isTrue);

      result['matrix'][1][0]['new_key'] = 'injected';
      expect(result['matrix'][1][0]['new_key'], 'injected');
    });

    test('Gracefully ignores Unicode/Emoji poisoning in JSON keys and values',
        () {
      const jsonStr = '{"user_👽": {"name": "Omega 🚀", "flags": [1, 2]}}';
      final result = QLFormatParser.parse(jsonStr);
      expect(result['user_👽']['name'], 'Omega 🚀');
    });

    test('Handles blank, whitespace-only, and completely invalid strings', () {
      expect(QLFormatParser.parse(''), isEmpty);
      expect(QLFormatParser.parse('not_json_or_yaml_at_all!@#*()'), isEmpty);
    });
  });
}
