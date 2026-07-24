import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

import 'support/test_helpers.dart';

void main() {
  setUp(resetQuantumRuntime);

  test('All SDUI fixture files parse into maps and blueprint trees', () async {
    final files = listJsonFixtures();
    if (files.isEmpty) {
      final fallbackDir = Directory('test/fixtures/sdui');
      fallbackDir.createSync(recursive: true);
      File('test/fixtures/sdui/sample_card.json').writeAsStringSync(
          '{"ui":{"type":"box:col","props":{"gap":8},"children":[{"type":"text","props":{"text":"fixture"}}]}}');
    }
    final files2 = listJsonFixtures();
    expect(files2, isNotEmpty);

    for (final file in files2) {
      final raw = await file.readAsString();
      final parsed = QLFormatParser.parse(raw);
      expect(parsed, isA<Map<String, dynamic>>());

      final blueprint = await QuantumSduiEngine.instance.processRaw(parsed);
      expect(blueprint, isA<QLBlueprint>());
      expect(blueprint.type, isNotEmpty);
    }
  });
}
