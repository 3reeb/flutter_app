/*
 * ============================================================================
 * File: quantum_export_dom_stub.dart
 * 
 * Description:
 * A stub implementation of the DOM export helpers for non-web platforms.
 * Provides no-op functions to ensure safe compilation when dart:html is 
 * unavailable on mobile or desktop targets.
 * 
 * Key Components:
 * - writePngToDom: No-op stub.
 * - signalReady: No-op stub.
 * - signalError: No-op stub.
 * 
 * Dependencies/Relationships:
 * Imported conditionally by quantum_export_web_bridge.dart when not compiling 
 * for the web.
 * 
 * Notes:
 * Never executed in web environments. Merely satisfies the dart compiler for 
 * native targets.
 * ============================================================================
 */
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
