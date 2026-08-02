/*
 * ============================================================================
 * File: quantum_export_dom_web.dart
 * 
 * Description:
 * The web-specific DOM interaction layer for the Quantum Image Export pipeline.
 * It writes rendered base64 PNG data directly into hidden HTML elements and 
 * sets dataset flags on the document body to signal completion or errors to 
 * headless scraper environments (like Puppeteer or Vercel edge functions).
 * 
 * Key Components:
 * - writePngToDom: Creates/updates #__qx_export_result with base64 data.
 * - signalReady: Sets qxReady='true' on the document body.
 * - signalError: Sets error flags on the document body.
 * 
 * Dependencies/Relationships:
 * Relies on dart:html. Imported conditionally by quantum_export_web_bridge.dart 
 * during web compilation.
 * 
 * Notes:
 * Ensure headless scrapers are configured to wait for the qxReady dataset 
 * attribute before attempting to extract the image text content.
 * ============================================================================
 */
// ════════════════════════════════════════════════════════════════════════════
// QUANTUM EXPORT DOM HELPER — web implementation (dart:html)
// quantum_export_dom_web.dart
//
// Only compiled on Flutter web. dart:html is always available there without
// any extra package.
// ════════════════════════════════════════════════════════════════════════════

// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

/// Writes [base64Png] into  #__qx_export_result  (creates it if needed).
/// Puppeteer reads:  document.getElementById('__qx_export_result').textContent
void writePngToDom(String base64Png) {
  var el = html.document.getElementById('__qx_export_result');
  if (el == null) {
    el = html.DivElement()
      ..id = '__qx_export_result'
      ..style.display = 'none';
    html.document.body?.append(el);
  }
  el.text = base64Png;
}

/// Sets  document.body.dataset['qxReady'] = 'true'
/// Puppeteer polls:  document.body?.dataset?.qxReady === 'true'
void signalReady() {
  html.document.body?.dataset['qxReady'] = 'true';
}

/// Records an error message for debugging in Puppeteer.
void signalError(String message) {
  html.document.body?.dataset['qxError'] = message;
  html.document.body?.dataset['qxReady'] = 'error';
}
