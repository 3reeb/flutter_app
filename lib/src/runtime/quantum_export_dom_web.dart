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
