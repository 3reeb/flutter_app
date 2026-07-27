// ════════════════════════════════════════════════════════════════════════════
// QUANTUM EXPORT DOM HELPER — stub (non-web platforms)
// quantum_export_dom_stub.dart
//
// On non-web platforms these are no-ops.
// The real implementation is in quantum_export_dom_web.dart.
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
void writePngToDom(String base64Png) {
  debugPrint('[QuantumExportBridge] PNG ready (${base64Png.length} chars) — '
      'non-web platform, DOM write skipped.');
}

void signalReady() {
  debugPrint('[QuantumExportBridge] signalReady() — non-web, no DOM.');
}

void signalError(String message) {
  debugPrint('[QuantumExportBridge] signalError: $message');
}
