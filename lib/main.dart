import 'dart:convert';
import 'package:flutter/material.dart';
import 'quantum.dart';
import 'downloader.dart';

void main() {
  bootQuantumApp(
    QuantumAppConfig(
      appName: 'Quantum Omega Studio',
      themeMode: ThemeMode.light,
      telemetry: const QuantumTelemetryConfig(
        enabled: true,
        enableFrameMonitorInDebug: false,
      ),
      vm: const QuantumVMConfig(workerThreads: 4, simdArenaCapacity: 16384),
      domains: [
        QuantumDomain(
          name: 'studio_domain',
          routes: [
            QLRouteBuilder.localJson(
                path: '/',
                schemaBuilder: (info) => {
                      'type': 'studio',
                    }),
          ],
          sduiComponents: {
            'studio': (ctx) => const SduiStudioWidget(),
          },
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN SYSTEM CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────
const Color _kPanelBg = Color(0xFF0F172A); // Slate 900
const Color _kEditorBg = Color(0xFF1E293B); // Slate 800
const Color _kHeaderBg = Color(0xFF020617); // Slate 950
const Color _kTextPrimary = Color(0xFFF8FAFC); // Slate 50
const Color _kTextMuted = Color(0xFF94A3B8); // Slate 400
const Color _kAccent = Color(0xFF6366F1); // Indigo 500
const Color _kCanvasBg = Color(0xFFF1F5F9); // Slate 100

// ─────────────────────────────────────────────────────────────────────────────
// STUDIO WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class SduiStudioWidget extends StatefulWidget {
  const SduiStudioWidget({super.key});

  @override
  State<SduiStudioWidget> createState() => _SduiStudioWidgetState();
}

class _SduiStudioWidgetState extends State<SduiStudioWidget> {
  final TextEditingController _controller = TextEditingController();
  Map<String, dynamic> _parsedJson = {};
  QLBlueprint? _compiledBlueprint;
  String _error = '';
  bool _isExporting = false;

  final String _initialJson = '''{
  "type": "col",
  "style": "p-32 rounded-3xl w-full max-w-md gap-32 bg-gradient-to-br from-indigo-900 via-purple-900 to-slate-900 shadow-[0_32px_64px_-16px_rgba(0,0,0,0.5)] border border-white/10",
  "children": [
    {
      "type": "row",
      "style": "w-full justify-between items-center",
      "children": [
        {
          "type": "row",
          "style": "items-center gap-16",
          "children": [
            {
              "type": "center",
              "style": "w-56 h-56 rounded-full bg-gradient-to-tr from-pink-500 to-orange-400 p-2 shadow-lg",
              "children": [
                {
                  "type": "avatar",
                  "props": {
                    "src": "https://i.pravatar.cc/150?u=quantum_omega",
                    "size": 52
                  }
                }
              ]
            },
            {
              "type": "col",
              "children": [
                {
                  "type": "text:h3",
                  "style": "text-white font-bold tracking-wide text-lg",
                  "props": { "text": "Aura Infinity" }
                },
                {
                  "type": "text:p",
                  "style": "text-indigo-300 text-sm font-medium mt-4",
                  "props": { "text": "@quantum_lead" }
                }
              ]
            }
          ]
        },
        {
          "type": "box",
          "style": "px-16 py-8 rounded-full bg-white/10 backdrop-blur-md border border-white/20 shadow-inner",
          "children": [
            {
              "type": "text:p",
              "style": "text-white text-xs font-bold tracking-widest uppercase",
              "props": { "text": "PRO" }
            }
          ]
        }
      ]
    },
    {
      "type": "box",
      "style": "w-full h-1 bg-white/10 rounded-full"
    },
    {
      "type": "row",
      "style": "w-full justify-between items-end",
      "children": [
        {
          "type": "col",
          "style": "gap-8",
          "children": [
            {
              "type": "text:p",
              "style": "text-slate-400 text-sm uppercase tracking-wider font-semibold",
              "props": { "text": "Total Balance" }
            },
            {
              "type": "text:h1",
              "style": "text-white text-5xl font-light tracking-tighter",
              "props": { "text": "\$24,592.00" }
            }
          ]
        },
        {
          "type": "action:button",
          "props": {
            "text": "Send",
            "intent": "indigo",
            "fill": "solid",
            "scale": "sm",
            "depth": "neon",
            "shape": "pill"
          }
        }
      ]
    }
  ]
}''';

  @override
  void initState() {
    super.initState();
    _controller.text = _initialJson;
    _parseJson();
  }

  void _parseJson() async {
    try {
      final parsed = jsonDecode(_controller.text);
      final blueprint = await QLCompiler.compileAsync(parsed, const {}, const {});
      if (mounted) {
        setState(() {
          _parsedJson = parsed;
          _compiledBlueprint = blueprint;
          _error = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _exportImage() async {
    if (_parsedJson.isEmpty) return;

    setState(() => _isExporting = true);
    try {
      final result = await QuantumWidgetImageExporter.export(
        json: _parsedJson,
        context: context,
        config: const QuantumExportConfig(
           width: 800,
           pixelRatio: 3.0,
           background: Colors.transparent,
        )
      );

      downloadImage(result.pngBytes, 'quantum_sdui_export.png');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Design successfully exported as PNG!'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'), 
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kCanvasBg,
      body: Column(
        children: [
          // ── HEADER ──
          Container(
            height: 64,
            decoration: const BoxDecoration(
              color: _kHeaderBg,
              border: Border(bottom: BorderSide(color: Colors.white10)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _kAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _kAccent.withOpacity(0.5)),
                      ),
                      child: const Icon(Icons.auto_awesome, color: _kAccent, size: 20),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Quantum SDUI Studio',
                      style: TextStyle(
                        color: _kTextPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('OMEGA CORE', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                Row(
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                      label: const Text('Render Output', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        backgroundColor: Colors.white10,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _parseJson,
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: _isExporting 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.ios_share_rounded, size: 18),
                      label: Text(_isExporting ? 'Exporting...' : 'Export to PNG'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: _isExporting ? null : _exportImage,
                    ),
                  ],
                )
              ],
            ),
          ),
          
          // ── WORKSPACE ──
          Expanded(
            child: Row(
              children: [
                // Editor Pane (Dark Mode)
                Expanded(
                  flex: 5,
                  child: Container(
                    color: _kEditorBg,
                    child: Column(
                      children: [
                        // Editor Tab
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: const BoxDecoration(
                            color: _kPanelBg,
                            border: Border(bottom: BorderSide(color: Colors.white10)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.code_rounded, color: _kTextMuted, size: 16),
                              const SizedBox(width: 8),
                              const Text('schema.json', style: TextStyle(color: _kTextMuted, fontSize: 13, fontWeight: FontWeight.w500)),
                              const Spacer(),
                              if (_error.isNotEmpty)
                                const Row(
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.redAccent, size: 14),
                                    SizedBox(width: 6),
                                    Text('Syntax Error', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                )
                            ],
                          ),
                        ),
                        // Editor TextField
                        Expanded(
                          child: Stack(
                            children: [
                              TextField(
                                controller: _controller,
                                maxLines: null,
                                expands: true,
                                style: const TextStyle(
                                  fontFamily: 'Consolas', 
                                  fontFamilyFallback: ['Courier New', 'monospace'],
                                  fontSize: 14, 
                                  color: _kTextPrimary,
                                  height: 1.5,
                                ),
                                cursorColor: _kAccent,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.only(left: 64, right: 24, top: 24, bottom: 24),
                                  fillColor: _kEditorBg,
                                  filled: true,
                                ),
                                onChanged: (_) => _parseJson(),
                              ),
                              // Faux Line Numbers Gutter
                              Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                width: 48,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: _kPanelBg,
                                    border: Border(right: BorderSide(color: Colors.white10)),
                                  ),
                                  padding: const EdgeInsets.only(top: 24),
                                  child: Column(
                                    children: List.generate(
                                      50, 
                                      (i) => Padding(
                                        padding: const EdgeInsets.only(bottom: 5.5), 
                                        child: Text('${i + 1}', style: const TextStyle(color: Colors.white24, fontSize: 12, fontFamily: 'Consolas')),
                                      )
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Error Panel
                        if (_error.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: Color(0xFF450A0A), // Red 950
                              border: Border(top: BorderSide(color: Colors.redAccent)),
                            ),
                            child: Text(_error, style: const TextStyle(color: Colors.redAccent, fontFamily: 'Consolas', fontSize: 13)),
                          )
                      ],
                    ),
                  ),
                ),
                
                // Divider
                Container(width: 1, color: Colors.black12),
                
                // Canvas Pane (Preview)
                Expanded(
                  flex: 6,
                  child: CustomPaint(
                    painter: _DotGridPainter(),
                    child: Center(
                      child: _compiledBlueprint != null
                          ? Container(
                              // Wrapper to ensure bounding box constraints aren't completely unconstrained 
                              // which might stretch the widget improperly.
                              margin: const EdgeInsets.all(40),
                              child: QuantumVM.instance.renderWidget(
                                context,
                                _compiledBlueprint!,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER FOR DESIGN CANVAS GRID
// ─────────────────────────────────────────────────────────────────────────────
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.fill;
    
    const double spacing = 24.0;
    const double radius = 1.5;

    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
