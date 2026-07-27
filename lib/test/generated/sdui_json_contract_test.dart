// Generated SDUI JSON contract suite.
// This file scans test/sdui_json/*.json and runs the declared assertions.

import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart' as quantum_layout;
import '../support/quantum_sdui_json_suite.dart';
void main() {
  test('quantum_layout SDUI snapshot is available for JSON tests', () {
    final snapshot = quantum_layout.QuantumSduiTypeEngine.exportSnapshot();
    expect(snapshot, isA<Map<String, dynamic>>());
    expect(snapshot, isNotEmpty);
    expect(snapshot.containsKey('omniCores'), isTrue);
  });

  defineQuantumSduiJsonSuite(folderPath: 'test/sdui_json');
}
