// ════════════════════════════════════════════════════════════════════════════
// QUANTUM EXPORT WEB BRIDGE v1.0
// quantum_export_web_bridge.dart
//
// PURPOSE:
//   Flutter-side counterpart of the Vercel render API (api/render.js).
//
//   The Vercel API launches headless Chromium, navigates to your Flutter
//   app at  /#/export?q=<base64-payload>, waits for this page to render
//   the SDUI JSON offscreen, then reads the PNG bytes from the DOM.
//
// REGISTER THE ROUTE — add ONE line to your QuantumAppConfig routes list:
//
//   QLRoute(
//     path: '/export',
//     builder: (context, info) => QuantumExportBridgePage(routeInfo: info),
//   ),
//
// ════════════════════════════════════════════════════════════════════════════

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../quantum.dart';

// Conditional import: on web dart:html is available → use real DOM writer.
// On every other platform → use the no-op stub.
import 'quantum_export_dom_stub.dart'
    if (dart.library.html) 'quantum_export_dom_web.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  PAYLOAD — decoded from the URL ?q= parameter
// ─────────────────────────────────────────────────────────────────────────────

class _ExportPayload {
  final Map<String, dynamic> json;
  final double width;
  final double? height;
  final double pixelRatio;
  final Color background;

  const _ExportPayload({
    required this.json,
    this.width = 390,
    this.height,
    this.pixelRatio = 2.0,
    this.background = Colors.transparent,
  });

  static _ExportPayload? fromBase64(String? q) {
    if (q == null || q.isEmpty) return null;
    try {
      // base64url → standard base64 + padding
      String padded = q.replaceAll('-', '+').replaceAll('_', '/');
      while (padded.length % 4 != 0) padded += '=';
      final decoded = utf8.decode(base64.decode(padded));
      final data = Map<String, dynamic>.from(jsonDecode(decoded) as Map);
      return _ExportPayload(
        json: Map<String, dynamic>.from((data['json'] as Map?) ?? data),
        width: (data['width'] as num?)?.toDouble() ?? 390,
        height: (data['height'] as num?)?.toDouble(),
        pixelRatio: (data['pixelRatio'] as num?)?.toDouble() ?? 2.0,
        background: _parseColor(data['background']?.toString() ?? ''),
      );
    } catch (e) {
      debugPrint('[QuantumExportBridge] Failed to parse payload: $e');
      return null;
    }
  }

  static Color _parseColor(String s) {
    if (s.isEmpty || s == 'transparent') return Colors.transparent;
    if (s.startsWith('#')) {
      try {
        final hex = s.replaceFirst('#', '');
        return Color(int.parse(hex.length == 6 ? 'FF$hex' : hex, radix: 16));
      } catch (_) {}
    }
    return Colors.white;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  EXPORT BRIDGE PAGE
// ─────────────────────────────────────────────────────────────────────────────

/// Register this at the `/export` route.
/// The Vercel API (api/render.js) will open this page in headless Chromium.
///
/// ```dart
/// // In QuantumAppConfig → domains → routes:
/// QLRoute(
///   path: '/export',
///   builder: (context, info) => QuantumExportBridgePage(routeInfo: info),
/// ),
/// ```
class QuantumExportBridgePage extends StatefulWidget {
  final QLRouteInfo? routeInfo;
  const QuantumExportBridgePage({super.key, this.routeInfo});

  @override
  State<QuantumExportBridgePage> createState() =>
      _QuantumExportBridgePageState();
}

class _QuantumExportBridgePageState extends State<QuantumExportBridgePage> {
  _Status _status = _Status.loading;
  String _message = 'Initializing…';
  QuantumExportResult? _result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    // ── 1. Decode the ?q= payload from the URL ─────────────────────────────
    final q = _queryParam('q');
    final payload = _ExportPayload.fromBase64(q);

    if (payload == null) {
      return _fail('Missing or invalid ?q= URL parameter.\n'
          'Expected: /#/export?q=<base64url-payload>');
    }

    _setMsg('Compiling SDUI schema…');

    // ── 2. Render with QuantumWidgetImageExporter ──────────────────────────
    try {
      final result = await QuantumWidgetImageExporter.export(
        json: payload.json,
        context: context,
        config: QuantumExportConfig(
          width: payload.width,
          height: payload.height,
          pixelRatio: payload.pixelRatio,
          background: payload.background,
          timeout: const Duration(seconds: 25),
        ),
      );

      // ── 3. Write PNG to DOM → Puppeteer reads it ───────────────────────
      writePngToDom(base64Encode(result.pngBytes));
      signalReady(); // sets document.body.dataset['qxReady'] = 'true'

      if (mounted) {
        setState(() {
          _result = result;
          _status = _Status.done;
          _message = '${result.pixelWidth}×${result.pixelHeight}px  '
              '${(result.pngBytes.length / 1024).toStringAsFixed(1)} KB  '
              '${result.elapsed.inMilliseconds}ms';
        });
      }
    } catch (e, st) {
      debugPrint('[QuantumExportBridge] ❌ $e\n$st');
      _fail(e.toString());
    }
  }

  void _fail(String msg) {
    signalError(msg);
    if (mounted) setState(() { _status = _Status.error; _message = msg; });
  }

  void _setMsg(String msg) {
    if (mounted) setState(() => _message = msg);
  }

  /// Reads ?q= from the URL — works for both hash-routing and path-routing.
  String? _queryParam(String name) {
    if (kIsWeb) {
      try {
        // Hash routing:  /#/export?q=xxx  →  Uri.base.fragment = "/export?q=xxx"
        final fragment = Uri.base.fragment;
        final qi = fragment.indexOf('?');
        if (qi >= 0) {
          final params = Uri.splitQueryString(fragment.substring(qi + 1));
          if (params.containsKey(name)) return params[name];
        }
        // Path routing fallback
        return Uri.base.queryParameters[name];
      } catch (_) {}
    }
    // Injected by the Quantum router for non-web platforms
    return widget.routeInfo?.queryParams[name];
  }

  // ── Status UI — only visible to a human who navigates to /export manually ─
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: switch (_status) {
        _Status.loading => const Color(0xFF06060E),
        _Status.done    => const Color(0xFF060E07),
        _Status.error   => const Color(0xFF0E0606),
      },
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Status icon
                Text(
                  switch (_status) {
                    _Status.loading => '⏳',
                    _Status.done    => '✅',
                    _Status.error   => '❌',
                  },
                  style: const TextStyle(fontSize: 52),
                ),
                const SizedBox(height: 20),
                // Label
                Text(
                  switch (_status) {
                    _Status.loading => 'RENDERING…',
                    _Status.done    => 'DONE',
                    _Status.error   => 'ERROR',
                  },
                  style: TextStyle(
                    color: switch (_status) {
                      _Status.loading => const Color(0xFF6366F1),
                      _Status.done    => const Color(0xFF22C55E),
                      _Status.error   => const Color(0xFFEF4444),
                    },
                    fontSize: 11,
                    letterSpacing: 3,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                // Message
                Text(
                  _message,
                  style: const TextStyle(
                    color: Color(0xFF8888AA),
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_status == _Status.loading)
                  const Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Color(0xFF6366F1),
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                // Preview of the captured image (debug convenience)
                if (_result != null) ...[
                  const SizedBox(height: 28),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF22C55E), width: 1),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.memory(
                      _result!.pngBytes,
                      width: 240,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _Status { loading, done, error }
