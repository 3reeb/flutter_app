// ════════════════════════════════════════════════════════════════════════════
// QUANTUM SDUI TEST ENGINE — stub fallback
// quantum_sdui_test_engine_stub.dart
//
// Web and other non-IO builds use this file. It exposes the same public API as
// the IO implementation so the conditional export stays compile-safe.
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'quantum_sdui_test_engine_shared.dart';
final class QuantumSduiTestEngine {
  static final QuantumSduiTestEngine instance = QuantumSduiTestEngine._();
  QuantumSduiTestEngine._();

  QuantumSduiTestReport? _lastReport;
  QuantumSduiTestReport? get lastReport => _lastReport;

  Future<List<QuantumSduiTestCase>> discoverFolder(
    String folderPath, {
    bool recursive = true,
  }) async {
    throw UnsupportedError(
      'QuantumSduiTestEngine.discoverFolder is not supported on this platform.',
    );
  }

  Future<QuantumSduiTestCase> loadCase(dynamic file) async {
    throw UnsupportedError(
      'QuantumSduiTestEngine.loadCase is not supported on this platform.',
    );
  }

  Future<QuantumSduiTestReport> runFolder(
    BuildContext context, {
    required String folderPath,
    bool recursive = true,
    bool stopOnFirstFailure = false,
    Size defaultViewport = const Size(390, 844),
    double defaultPixelRatio = 1.0,
    Duration timeout = const Duration(seconds: 8),
    String? outputJsonPath,
    String? outputImageDirectory,
  }) async {
    throw UnsupportedError(
      'QuantumSduiTestEngine.runFolder is not supported on this platform.',
    );
  }

  Future<QuantumSduiTestResult> runCase(
    BuildContext context,
    QuantumSduiTestCase testCase, {
    Size? viewport,
    double? pixelRatio,
    Duration? timeout,
    String? outputImageDirectory,
  }) async {
    throw UnsupportedError(
      'QuantumSduiTestEngine.runCase is not supported on this platform.',
    );
  }

  Future<QuantumSduiTestReport> collectAll({
    String folderPath = 'test/sdui_json',
    bool recursive = true,
  }) async {
    throw UnsupportedError(
      'QuantumSduiTestEngine.collectAll is not supported on this platform.',
    );
  }
}
