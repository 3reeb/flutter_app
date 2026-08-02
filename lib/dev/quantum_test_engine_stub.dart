// ════════════════════════════════════════════════════════════════════════════
// QUANTUM TEST ENGINE — stub implementation
// src/runtime/quantum_test_engine_stub.dart
// ════════════════════════════════════════════════════════════════════════════

import 'quantum_test_engine_shared.dart';
final class QuantumTestEngine {
  static final QuantumTestEngine instance = QuantumTestEngine._();
  QuantumTestEngine._();

  Future<List<QuantumTestManifest>> discoverManifests(
      {String rootPath = 'lib/docs_tests/yaml/by-file'}) async {
    throw UnsupportedError(
        'QuantumTestEngine is not available on this platform.');
  }

  QuantumTestManifest loadManifestSync(String manifestPath) {
    throw UnsupportedError(
        'QuantumTestEngine is not available on this platform.');
  }

  List<QuantumTestIssue> validateManifest(QuantumTestManifest manifest,
      {String? sourceText, bool strict = true}) {
    return manifest.validate(sourceText: sourceText, strict: strict);
  }

  Future<void> writeRuntimeReportBundle(QuantumTestReport report,
      {required String outputRoot, bool compact = true}) async {
    throw UnsupportedError('QuantumTestEngine is not available on this platform.');
  }
}
