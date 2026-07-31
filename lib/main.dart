import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quantum_layout/src/runtime/quantum_sdui_test_engine_io.dart';
import 'package:flutter/rendering.dart';
import 'package:quantum_layout/downloader.dart';
import 'package:quantum_layout/quantum.dart';
import 'src/showcase/media_showcase.dart';

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
              schemaBuilder: (info) => {'type': 'studio'},
            ),
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
const Color _kSurface = Color(0xFFFFFFFF);

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
  Timer? _parseDebounce;

  final List<_StudioExample> _examples = [];
  final Map<String, _ExampleHealthResult> _exampleResults = {};

  dynamic _parsedJson;
  QLBlueprint? _compiledBlueprint;
  String _error = '';
  String _stackTrace = '';
  String _status = 'Paste JSON, then render it.';
  String _healthStatus = 'Example registry is empty.';
  String? _selectedExampleId;
  bool _isExportingImage = false;
  bool _isExportingJson = false;
  bool _isRunningAllExamples = false;
  String _lastErrorSignature = '';
  String _blankRenderWarning = '';
  Size _lastPreviewSize = Size.zero;
  int _exampleCounter = 0;

  static const String _initialJson = r'''{
  "type": "box:col",
  "style": "p-32 rounded-3xl w-full max-w-xl gap-24 bg-gradient-to-br from-indigo-900 via-purple-900 to-slate-900 shadow-[0_32px_64px_-16px_rgba(0,0,0,0.5)] border border-white/10",
  "children": [
    {
      "type": "box:row",
      "style": "w-full justify-between items-center",
      "children": [
        {
          "type": "box:row",
          "style": "items-center gap-16",
          "children": [
            {
              "type": "box:center",
              "style": "w-56 h-56 rounded-full bg-gradient-to-tr from-pink-500 to-orange-400 p-2 shadow-lg",
              "children": [
                {
                  "type": "media:avatar",
                  "props": {
                    "src": "https://i.pravatar.cc/150?u=quantum_omega",
                    "size": 52
                  }
                }
              ]
            },
            {
              "type": "box:col",
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
      "type": "box:row",
      "style": "w-full justify-between items-end gap-16",
      "children": [
        {
          "type": "box:col",
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
              "props": { "text": "$24,592.00" }
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
    _registerSeedExamples();
    _controller.text = _initialJson;
    _selectedExampleId = _examples.isNotEmpty ? _examples.first.id : null;
    _scheduleParse(immediate: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _runAllExampleHealth(silent: true);
    });
  }

  @override
  void dispose() {
    _parseDebounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String _sanitizeJson(String input) {
    var text = input.trim();

    if (text.startsWith('```')) {
      final lines = text.split('\n');
      if (lines.isNotEmpty && lines.first.trim().startsWith('```')) {
        lines.removeAt(0);
      }
      if (lines.isNotEmpty && lines.last.trim() == '```') {
        lines.removeLast();
      }
      text = lines.join('\n').trim();
    }

    if (text.startsWith('json\n')) {
      text = text.substring(5).trimLeft();
    }

    if (text.startsWith('JSON\n')) {
      text = text.substring(5).trimLeft();
    }

    return text;
  }

  String _prettyJson(String raw) {
    final sanitized = _sanitizeJson(raw);
    final parsed = jsonDecode(sanitized);
    return const JsonEncoder.withIndent('  ').convert(parsed);
  }

  String _deriveExampleName(String jsonText) {
    final sanitized = _sanitizeJson(jsonText);
    try {
      final dynamic parsed = jsonDecode(sanitized);
      if (parsed is Map) {
        final type = parsed['type']?.toString().trim();
        final title = parsed['title']?.toString().trim();
        if (title != null && title.isNotEmpty) return title;
        if (type != null && type.isNotEmpty) return type;
      }
    } catch (_) {
      // Ignore — fallback below.
    }

    final firstLine = sanitized.split('\\n').first.trim();
    if (firstLine.isNotEmpty)
      return firstLine.length > 40 ? firstLine.substring(0, 40) : firstLine;
    return 'Untitled Example';
  }

  void _setEditorText(String value, {bool pretty = false}) {
    var text = _sanitizeJson(value);
    if (pretty && text.isNotEmpty) {
      try {
        text = _prettyJson(text);
      } catch (_) {
        // Keep raw content if formatting fails.
      }
    }

    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
      composing: TextRange.empty,
    );
    _scheduleParse(immediate: true);
  }

  void _scheduleParse({bool immediate = false}) {
    _parseDebounce?.cancel();
    _parseDebounce = Timer(
      immediate ? Duration.zero : const Duration(milliseconds: 180),
      _parseJson,
    );
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text ?? '';
    if (text.trim().isEmpty) {
      _toast('Clipboard is empty.');
      return;
    }
    _setEditorText(text, pretty: true);
    _toast('Pasted JSON from clipboard.');
  }

  void _loadSample() {
    _setEditorText(_initialJson, pretty: true);
    _toast('Loaded sample JSON.');
  }

  void _registerSeedExamples() {
    if (_examples.isNotEmpty) return;

    final seeds = _seedExamples();
    _examples.addAll(seeds);
    for (final example in seeds) {
      _exampleResults[example.id] = _ExampleHealthResult.pending(example.id);
    }
    _healthStatus = 'Loaded ${_examples.length} built-in examples.';
  }

  List<_StudioExample> _seedExamples() => [
        _StudioExample(
          id: 'starter-profile',
          title: 'Starter Profile',
          category: 'cards',
          description: 'A polished hero card with title, avatar, and action.',
          json: _initialJson,
        ),
        _StudioExample(
          id: 'auth-login',
          title: 'Auth Login Form',
          category: 'forms',
          description: 'Text fields, password field, remember me, and CTA.',
          json: const JsonEncoder.withIndent('  ').convert({
            'type': 'box:col',
            'style': 'p-24 rounded-3xl gap-16 bg-white shadow-lg',
            'children': [
              {
                'type': 'text:h2',
                'props': {'text': 'Welcome back'}
              },
              {
                'type': 'text:p',
                'props': {'text': 'Sign in to continue to your workspace.'}
              },
              {
                'type': 'field:text',
                'props': {'label': 'Email', 'placeholder': 'name@company.com'}
              },
              {
                'type': 'field:password',
                'props': {'label': 'Password', 'placeholder': '••••••••'}
              },
              {
                'type': 'box:row',
                'style': 'items-center justify-between',
                'children': [
                  {
                    'type': 'field:checkbox',
                    'props': {'label': 'Remember me'}
                  },
                  {
                    'type': 'text:p',
                    'props': {'text': 'Forgot password?'}
                  },
                ]
              },
              {
                'type': 'action:button',
                'props': {'text': 'Sign in', 'intent': 'indigo'}
              },
            ],
          }),
        ),
        _StudioExample(
          id: 'dashboard-metrics',
          title: 'Dashboard Metrics',
          category: 'dashboards',
          description: 'Metric cards arranged in a responsive grid.',
          json: const JsonEncoder.withIndent('  ').convert({
            'type': 'box:col',
            'style': 'p-24 gap-16',
            'children': [
              {
                'type': 'text:h3',
                'props': {'text': 'Workspace Health'}
              },
              {
                'type': 'box:grid',
                'props': {'columns': 2, 'gap': 16},
                'children': [
                  {
                    'type': 'box',
                    'style': 'p-16 rounded-2xl bg-slate-900 text-white',
                    'children': [
                      {
                        'type': 'text:h2',
                        'props': {'text': '124'}
                      }
                    ]
                  },
                  {
                    'type': 'box',
                    'style': 'p-16 rounded-2xl bg-emerald-500 text-white',
                    'children': [
                      {
                        'type': 'text:h2',
                        'props': {'text': '98.4%'}
                      }
                    ]
                  },
                  {
                    'type': 'box',
                    'style': 'p-16 rounded-2xl bg-amber-500 text-white',
                    'children': [
                      {
                        'type': 'text:h2',
                        'props': {'text': '12'}
                      }
                    ]
                  },
                  {
                    'type': 'box',
                    'style': 'p-16 rounded-2xl bg-indigo-500 text-white',
                    'children': [
                      {
                        'type': 'text:h2',
                        'props': {'text': '32ms'}
                      }
                    ]
                  },
                ]
              },
            ],
          }),
        ),
        _StudioExample(
          id: 'settings-list',
          title: 'Settings List',
          category: 'lists',
          description: 'A dense settings layout with toggles and labels.',
          json: const JsonEncoder.withIndent('  ').convert({
            'type': 'box:col',
            'style': 'p-24 gap-12 bg-white rounded-3xl',
            'children': [
              {
                'type': 'text:h3',
                'props': {'text': 'Settings'}
              },
              {
                'type': 'box:row',
                'style': 'items-center justify-between',
                'children': [
                  {
                    'type': 'text:p',
                    'props': {'text': 'Dark mode'}
                  },
                  {
                    'type': 'field:toggle',
                    'props': {'value': true}
                  }
                ]
              },
              {
                'type': 'box:row',
                'style': 'items-center justify-between',
                'children': [
                  {
                    'type': 'text:p',
                    'props': {'text': 'Notifications'}
                  },
                  {
                    'type': 'field:toggle',
                    'props': {'value': false}
                  }
                ]
              },
              {
                'type': 'box:row',
                'style': 'items-center justify-between',
                'children': [
                  {
                    'type': 'text:p',
                    'props': {'text': 'Sync over mobile data'}
                  },
                  {
                    'type': 'field:toggle',
                    'props': {'value': false}
                  }
                ]
              },
            ],
          }),
        ),
        _StudioExample(
          id: 'empty-state',
          title: 'Empty State',
          category: 'states',
          description: 'A friendly empty state with a strong call to action.',
          json: const JsonEncoder.withIndent('  ').convert({
            'type': 'box:col',
            'style': 'p-24 items-center gap-16 rounded-3xl bg-slate-50',
            'children': [
              {
                'type': 'visual:icon',
                'props': {'name': 'inbox', 'size': 48}
              },
              {
                'type': 'text:h3',
                'props': {'text': 'Nothing here yet'}
              },
              {
                'type': 'text:p',
                'props': {
                  'text': 'Create your first item and it will appear here.'
                }
              },
              {
                'type': 'action:button',
                'props': {'text': 'Create first item', 'intent': 'indigo'}
              },
            ],
          }),
        ),
        _StudioExample(
          id: 'commerce-card',
          title: 'Commerce Card',
          category: 'commerce',
          description: 'Pricing / upsell style card with emphasis and CTA.',
          json: const JsonEncoder.withIndent('  ').convert({
            'type': 'box:col',
            'style':
                'p-24 rounded-3xl gap-16 bg-gradient-to-br from-slate-900 to-slate-700 text-white',
            'children': [
              {
                'type': 'text:h2',
                'props': {'text': 'Pro Plan'}
              },
              {
                'type': 'text:p',
                'props': {'text': 'Unlimited projects, exports, and previews.'}
              },
              {
                'type': 'action:button',
                'props': {
                  'text': 'Upgrade now',
                  'intent': 'emerald',
                  'fill': 'solid'
                }
              },
            ],
          }),
        ),
        _StudioExample(
          id: 'error-state',
          title: 'Error State',
          category: 'states',
          description: 'A recoverable error panel with retry semantics.',
          json: const JsonEncoder.withIndent('  ').convert({
            'type': 'box:col',
            'style': 'p-24 rounded-3xl gap-16 bg-red-50 border border-red-200',
            'children': [
              {
                'type': 'text:h3',
                'props': {'text': 'Something went wrong'}
              },
              {
                'type': 'text:p',
                'props': {
                  'text':
                      'The engine isolated this failure so other examples stay healthy.'
                }
              },
              {
                'type': 'action:button',
                'props': {'text': 'Retry', 'intent': 'red'}
              },
            ],
          }),
        ),
      ];

  Future<void> _registerCurrentExample() async {
    final current = _sanitizeJson(_controller.text);
    if (current.isEmpty) {
      _toast('Paste JSON first.', isError: true);
      return;
    }

    final suggestedName = _deriveExampleName(current);
    final name = await _askForText(
      title: 'Register example',
      label: 'Example name',
      initialValue: suggestedName,
      helperText:
          'This example will be added to the registry and tested with the rest.',
    );
    if (name == null || name.trim().isEmpty) return;

    final id = _uniqueExampleId(name);
    Map<String, dynamic> normalized;
    try {
      normalized = Map<String, dynamic>.from(jsonDecode(current) as Map);
    } catch (e) {
      _toast('Example is not valid JSON: $e', isError: true);
      return;
    }

    final example = _StudioExample(
      id: id,
      title: name.trim(),
      category: 'custom',
      description: 'User-registered example.',
      json: const JsonEncoder.withIndent('  ').convert(normalized),
    );

    setState(() {
      _examples.insert(0, example);
      _exampleResults[id] = _ExampleHealthResult.pending(id);
      _selectedExampleId = id;
      _healthStatus = 'Registered "${example.title}".';
    });
    _toast('Example registered.');
  }

  Future<String?> _askForText({
    required String title,
    required String label,
    required String initialValue,
    String? helperText,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              helperText: helperText,
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return result;
  }

  String _uniqueExampleId(String name) {
    final base = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    _exampleCounter++;
    return '$base-${_exampleCounter.toString().padLeft(2, '0')}';
  }

  Future<_ExampleHealthResult> _runExampleHealth(_StudioExample example) async {
    final watch = Stopwatch()..start();
    try {
      final parsed = jsonDecode(_sanitizeJson(example.json));
      final blueprint =
          await QLCompiler.compileAsync(parsed, const {}, const {});
      watch.stop();
      return _ExampleHealthResult(
        exampleId: example.id,
        ok: true,
        message: 'Compiled in ${watch.elapsedMilliseconds}ms',
        duration: watch.elapsed,
        compiledBlueprint: blueprint,
      );
    } catch (e, st) {
      watch.stop();
      return _ExampleHealthResult(
        exampleId: example.id,
        ok: false,
        message: e.toString(),
        stackTrace: st.toString(),
        duration: watch.elapsed,
      );
    }
  }

  Future<void> _runAllExampleHealth({bool silent = false}) async {
    if (_isRunningAllExamples) return;
    if (_examples.isEmpty) return;

    setState(() {
      _isRunningAllExamples = true;
      _healthStatus =
          'Running engine health checks across ${_examples.length} examples...';
    });

    final Map<String, _ExampleHealthResult> next = {};
    int okCount = 0;
    for (final example in _examples) {
      final result = await _runExampleHealth(example);
      next[example.id] = result;
      if (result.ok) okCount++;
    }

    if (!mounted) return;
    setState(() {
      _exampleResults
        ..clear()
        ..addAll(next);
      _isRunningAllExamples = false;
      _healthStatus = '$okCount/${_examples.length} examples are healthy.';
      _status = silent ? _status : _healthStatus;
    });

    if (!silent) {
      _toast(_healthStatus, isError: okCount != _examples.length);
    }
  }

  Future<void> _runFolderTests() async {
    if (_isRunningAllExamples) return;

    setState(() {
      _isRunningAllExamples = true;
      _healthStatus = 'Running folder-based SDUI tests in sdui_tests...';
    });

    try {
      final report = await QuantumSduiTestEngine.instance.runFolder(
        context,
        folderPath: 'sdui_tests',
        recursive: true,
        outputJsonPath: 'build/reports/sdui-report.json',
        outputImageDirectory: 'build/reports/screenshots',
        timeout: const Duration(seconds: 8),
      );

      if (!mounted) return;
      setState(() {
        _isRunningAllExamples = false;
        _healthStatus = report.healthy
            ? 'Folder tests passed: ${report.passed}/${report.total}'
            : 'Folder tests failed: ${report.failed}/${report.total}';
        _status = _healthStatus;
        if (report.results.isNotEmpty && !report.healthy) {
          final failed = report.results.firstWhere((r) => !r.ok);
          _error = failed.message ?? 'ssssssssss';
          _stackTrace = failed.stackTrace ?? '';
        } else {
          _error = '';
          _stackTrace = '';
        }
      });

      _toast(_healthStatus, isError: !report.healthy);
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _isRunningAllExamples = false;
        _healthStatus = 'Folder test engine error.';
        _status = _healthStatus;
        _error = e.toString();
        _stackTrace = st.toString();
      });
      _toast('Folder tests failed to run: $e', isError: true);
    }
  }

  Future<void> _testExample(_StudioExample example) async {
    final result = await _runExampleHealth(example);
    if (!mounted) return;
    setState(() {
      _exampleResults[example.id] = result;
      _healthStatus =
          result.ok ? '${example.title} passed.' : '${example.title} failed.';
      _status = _healthStatus;
    });
    _toast(
        result.ok
            ? '${example.title} passed health.'
            : '${example.title} failed health.',
        isError: !result.ok);
  }

  Future<void> _loadExample(_StudioExample example) async {
    _selectedExampleId = example.id;
    _setEditorText(example.json, pretty: true);
    _toast('Loaded ${example.title}.');
  }

  void _removeExample(String id) {
    final index = _examples.indexWhere((e) => e.id == id);
    if (index < 0) return;
    final removed = _examples.removeAt(index);
    _exampleResults.remove(id);
    if (_selectedExampleId == id) {
      _selectedExampleId = _examples.isNotEmpty ? _examples.first.id : null;
    }
    setState(() {
      _healthStatus = 'Removed ${removed.title}.';
    });
    _toast('Removed example ${removed.title}.');
  }

  Future<void> _formatJson() async {
    try {
      final formatted = _prettyJson(_controller.text);
      _setEditorText(formatted);
      _toast('Formatted JSON.');
    } catch (e) {
      _toast('Cannot format invalid JSON: $e', isError: true);
    }
  }

  Future<void> _copyJsonToClipboard() async {
    final text = _sanitizeJson(_controller.text);
    if (text.isEmpty) {
      _toast('Nothing to copy.', isError: true);
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    _toast('JSON copied to clipboard.');
  }

  Future<void> _parseJson() async {
    final rawText = _sanitizeJson(_controller.text);

    if (rawText.isEmpty) {
      if (!mounted) return;
      setState(() {
        _parsedJson = null;
        _compiledBlueprint = null;
        _error = '';
        _status = 'Paste JSON, then render it.';
        _blankRenderWarning = '';
      });
      return;
    }

    try {
      final parsed = jsonDecode(rawText);
      final blueprint =
          await QLCompiler.compileAsync(parsed, const {}, const {});

      if (!mounted) return;
      setState(() {
        _parsedJson = parsed;
        _compiledBlueprint = blueprint;
        _error = '';
        _stackTrace = '';
        _status = 'Valid JSON · Ready to render and export.';
        _blankRenderWarning = '';
      });
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _parsedJson = null;
        _compiledBlueprint = null;
        _error = e.toString();
        _stackTrace = st.toString();
        _status = 'JSON validation failed.';
        _blankRenderWarning = '';
      });
    }
  }

  Future<void> _exportJsonFile() async {
    if (_isExportingJson) return;

    setState(() => _isExportingJson = true);
    try {
      final currentText = _sanitizeJson(_controller.text);
      if (currentText.isEmpty) {
        throw StateError('JSON editor is empty.');
      }

      dynamic parsed = _parsedJson;
      if (parsed == null) {
        parsed = jsonDecode(currentText);
      }

      final formatted = const JsonEncoder.withIndent('  ').convert(parsed);
      final savedPath = await downloadText(
        formatted,
        'quantum_sdui_export.json',
        mimeType: 'application/json',
      );

      if (mounted) {
        _toast('JSON exported successfully.');
        setState(() {
          _status = 'Exported JSON to $savedPath';
        });
      }
    } catch (e) {
      if (mounted) {
        _toast('JSON export failed: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isExportingJson = false);
      }
    }
  }

  Future<void> _exportImage() async {
    if (_isExportingImage) return;
    if (_parsedJson == null) {
      _toast('Render valid JSON before exporting PNG.', isError: true);
      return;
    }

    setState(() => _isExportingImage = true);
    try {
      final result = await QuantumWidgetImageExporter.export(
        json: _parsedJson,
        context: context,
        config: const QuantumExportConfig(
          width: 1200,
          pixelRatio: 3.0,
          background: Colors.transparent,
        ),
      );

      await downloadImage(result.pngBytes, 'quantum_sdui_export.png');

      if (mounted) {
        _toast('PNG exported successfully.');
      }
    } catch (e) {
      if (mounted) {
        _toast('PNG export failed: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isExportingImage = false);
      }
    }
  }

  void _toast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kCanvasBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isDesktop = constraints.maxWidth >= 1080;
            final double editorHeight =
                (constraints.maxHeight * 0.48).clamp(320.0, 560.0);

            return Column(
              children: [
                _buildHeader(isDesktop),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: isDesktop
                        ? Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: _buildEditorPane(
                                  showLineNumbers: true,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 6,
                                child: _buildPreviewPane(isDesktop: isDesktop),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              SizedBox(
                                height: editorHeight,
                                child: _buildEditorPane(
                                  showLineNumbers: false,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                  child:
                                      _buildPreviewPane(isDesktop: isDesktop)),
                            ],
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDesktop) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _kHeaderBg,
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 16,
        vertical: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kAccent.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kAccent.withOpacity(0.35)),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: _kAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Quantum SDUI Studio',
                  style: TextStyle(
                    color: _kTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (isDesktop) ...[
                _buildStatusChip(),
                const SizedBox(width: 8),
                _buildHealthChip(),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _toolbarButton(
                icon: Icons.content_paste_rounded,
                label: 'Paste JSON',
                onPressed: _pasteFromClipboard,
                filled: false,
              ),
              _toolbarButton(
                icon: Icons.auto_fix_high_rounded,
                label: 'Format',
                onPressed: _formatJson,
                filled: false,
              ),
              _toolbarButton(
                icon: Icons.copy_rounded,
                label: 'Copy JSON',
                onPressed: _copyJsonToClipboard,
                filled: false,
              ),
              _toolbarButton(
                icon: Icons.person_add_alt_1_rounded,
                label: 'Register Example',
                onPressed: _registerCurrentExample,
                filled: false,
              ),
              _toolbarButton(
                icon: Icons.playlist_play_rounded,
                label: _isRunningAllExamples ? 'Testing...' : 'Run All',
                onPressed:
                    _isRunningAllExamples ? null : () => _runAllExampleHealth(),
                filled: false,
              ),
              _toolbarButton(
                icon: Icons.save_rounded,
                label: _isExportingJson ? 'Saving...' : 'Export JSON',
                onPressed: _isExportingJson ? null : _exportJsonFile,
                filled: true,
              ),
              _toolbarButton(
                icon: _isExportingImage
                    ? Icons.hourglass_top_rounded
                    : Icons.image_rounded,
                label: _isExportingImage ? 'Exporting...' : 'Export PNG',
                onPressed: _isExportingImage ? null : _exportImage,
                filled: true,
              ),
              _toolbarButton(
                icon: Icons.refresh_rounded,
                label: 'Render',
                onPressed: _parseJson,
                filled: false,
              ),
              _toolbarButton(
                icon: Icons.menu_book_rounded,
                label: 'Load Sample',
                onPressed: _loadSample,
                filled: false,
              ),
              _toolbarButton(
                icon: Icons.perm_media_rounded,
                label: 'Media Showcase',
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MediaShowcaseScreen()));
                },
                filled: true,
              ),
            ],
          ),
          if (!isDesktop) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatusChip(),
                _buildHealthChip(),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    final bool hasError = _error.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: hasError
            ? Colors.red.shade900.withOpacity(0.45)
            : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: hasError ? Colors.redAccent.withOpacity(0.65) : Colors.white12,
        ),
      ),
      child: Text(
        _status,
        style: TextStyle(
          color: hasError ? Colors.redAccent.shade100 : Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildHealthChip() {
    final int total = _examples.length;
    final int tested = _exampleResults.values.where((r) => r.hasRun).length;
    final int healthy =
        _exampleResults.values.where((r) => r.hasRun && r.ok).length;
    final int failed =
        _exampleResults.values.where((r) => r.hasRun && !r.ok).length;
    final bool unhealthy = failed > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: unhealthy
            ? Colors.orange.shade900.withOpacity(0.35)
            : Colors.green.shade900.withOpacity(0.25),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: unhealthy
              ? Colors.orangeAccent.withOpacity(0.55)
              : Colors.greenAccent.withOpacity(0.35),
        ),
      ),
      child: Text(
        total == 0
            ? 'No examples'
            : 'Health $healthy/$tested · $failed fail · $total total',
        style: TextStyle(
          color: unhealthy
              ? Colors.orangeAccent.shade100
              : Colors.greenAccent.shade100,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _toolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required bool filled,
  }) {
    final buttonStyle = filled
        ? ElevatedButton.styleFrom(
            backgroundColor: _kAccent,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          )
        : OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          );

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );

    return filled
        ? ElevatedButton(
            onPressed: onPressed,
            style: buttonStyle,
            child: child,
          )
        : OutlinedButton(
            onPressed: onPressed,
            style: buttonStyle,
            child: child,
          );
  }

  Widget _buildEditorPane({required bool showLineNumbers}) {
    return Container(
      decoration: BoxDecoration(
        color: _kEditorBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
        boxShadow: const [
          BoxShadow(
            blurRadius: 24,
            offset: Offset(0, 12),
            color: Color(0x14000000),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: _kPanelBg,
              border: Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                const Icon(Icons.code_rounded, color: _kTextMuted, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'schema.json',
                  style: TextStyle(
                    color: _kTextMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_error.isNotEmpty) ...[
                  const Icon(Icons.error_outline,
                      color: Colors.redAccent, size: 14),
                  const SizedBox(width: 6),
                  const Text(
                    'Syntax Error',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ] else ...[
                  const Icon(Icons.verified_rounded,
                      color: Colors.greenAccent, size: 14),
                  const SizedBox(width: 6),
                  const Text(
                    'Valid',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
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
                    contentPadding: EdgeInsets.only(
                      left: showLineNumbers ? 64 : 16,
                      right: 20,
                      top: 20,
                      bottom: 20,
                    ),
                    fillColor: _kEditorBg,
                    filled: true,
                  ),
                  onChanged: (_) => _scheduleParse(),
                ),
                if (showLineNumbers)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 48,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: _kPanelBg,
                        border: Border(
                          right: BorderSide(color: Colors.white10),
                        ),
                      ),
                      child: _LineNumberGutter(controller: _controller),
                    ),
                  ),
              ],
            ),
          ),
          if (_error.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFF450A0A),
                border: Border(top: BorderSide(color: Colors.redAccent)),
              ),
              child: SelectableText(
                _error,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontFamily: 'Consolas',
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreviewPane({required bool isDesktop}) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(
            blurRadius: 24,
            offset: Offset(0, 12),
            color: Color(0x12000000),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              flex: isDesktop ? 6 : 5,
              child: _buildPreviewSurface(),
            ),
            const SizedBox(height: 12),
            Expanded(
              flex: isDesktop ? 4 : 5,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildErrorPanel(),
                  const SizedBox(height: 12),
                  _buildHealthPanel(),
                  const SizedBox(height: 12),
                  _buildExamplesPanel(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSurface() {
    return CustomPaint(
      painter: _DotGridPainter(),
      child: QLErrorBoundary(
        label: 'selected-preview',
        maxRetries: 0,
        onError: (state) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _captureRenderError(
              state.error,
              stackTrace: state.stackTrace,
              source: 'Preview',
            );
          });
        },
        fallback: (context, error, retry) => _runtimeErrorSurface(error, retry),
        builder: (context) {
          if (_compiledBlueprint == null) {
            return Center(child: _buildEmptyPreviewState());
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: ClipRect(
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: _MeasureSize(
                        onChange: _handlePreviewSize,
                        child: QuantumVM.instance.renderWidget(
                          context,
                          _compiledBlueprint!,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _runtimeErrorSurface(QLErrorState error, VoidCallback? retry) {
    final text = error.error.toString();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          elevation: 0,
          color: const Color(0xFFFFF7ED),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.deepOrange),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Preview runtime error',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy error',
                      onPressed: () => Clipboard.setData(ClipboardData(
                          text: '$text\n\n${error.stackTrace ?? ''}')),
                      icon: const Icon(Icons.copy_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(text),
                if ((error.stackTrace?.toString() ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Stack trace',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    error.stackTrace!.toString(),
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade800,
                        fontFamily: 'Consolas'),
                  ),
                ],
                if (retry != null) ...[
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: retry,
                    child: const Text('Retry'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPreviewState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _error.isEmpty
                  ? Icons.preview_rounded
                  : Icons.warning_amber_rounded,
              size: 52,
              color: _error.isEmpty ? Colors.blueGrey : Colors.orange,
            ),
            const SizedBox(height: 14),
            Text(
              _error.isEmpty
                  ? (_blankRenderWarning.isNotEmpty
                      ? 'Blank render detected.'
                      : 'Preview waiting for JSON.')
                  : 'Fix JSON to render preview.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error.isEmpty
                  ? (_blankRenderWarning.isNotEmpty
                      ? _blankRenderWarning
                      : 'Paste a full SDUI document, register examples, and run the engine health checks.')
                  : 'The editor catches invalid JSON before export and before render, so the workflow stays safe.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPanel() {
    final hasError = _error.trim().isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: hasError ? const Color(0xFFFFF1F2) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: hasError ? Colors.red.shade200 : Colors.black12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                  hasError
                      ? Icons.error_outline_rounded
                      : Icons.verified_rounded,
                  color: hasError ? Colors.redAccent : Colors.green),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Latest error log',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Copy error',
                onPressed: hasError ? _copyLastError : null,
                icon: const Icon(Icons.copy_all_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            hasError
                ? _error
                : (_blankRenderWarning.isNotEmpty
                    ? _blankRenderWarning
                    : 'No parser or render errors right now.'),
            style: const TextStyle(fontSize: 12.5, height: 1.45),
          ),
          if (_stackTrace.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Stack trace',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade700)),
            const SizedBox(height: 4),
            SelectableText(
              _stackTrace,
              style: const TextStyle(
                  fontSize: 11, fontFamily: 'Consolas', height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHealthPanel() {
    final int total = _examples.length;
    final int tested = _exampleResults.values.where((r) => r.hasRun).length;
    final int healthy =
        _exampleResults.values.where((r) => r.hasRun && r.ok).length;
    final int failed =
        _exampleResults.values.where((r) => r.hasRun && !r.ok).length;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.health_and_safety_rounded,
                  color: Colors.lightGreenAccent),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Render engine health',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
              FilledButton.tonal(
                onPressed:
                    _isRunningAllExamples ? null : () => _runAllExampleHealth(),
                child: Text(_isRunningAllExamples ? 'Testing...' : 'Run all'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill('$healthy healthy', Colors.greenAccent),
              _pill('$failed failed', Colors.orangeAccent),
              _pill('$tested tested', Colors.lightBlueAccent),
              _pill('$total total', Colors.white70),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _healthStatus,
            style: const TextStyle(
                color: Colors.white70, fontSize: 12.5, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildExamplesPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.library_books_rounded, color: _kAccent),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Example registry',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              TextButton.icon(
                onPressed: _registerCurrentExample,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Register'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_examples.isEmpty)
            const Text('No examples registered yet.')
          else
            ..._examples.map(_buildExampleCard),
        ],
      ),
    );
  }

  Widget _buildExampleCard(_StudioExample example) {
    final result = _exampleResults[example.id];
    final bool loaded = _selectedExampleId == example.id;
    final bool hasResult = result?.hasRun == true;
    final bool ok = result?.ok == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: loaded ? const Color(0xFFF5F7FF) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: loaded ? _kAccent.withOpacity(0.35) : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(example.title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(example.category,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              _pill(
                  hasResult ? (ok ? 'pass' : 'fail') : 'pending',
                  ok
                      ? Colors.green
                      : hasResult
                          ? Colors.orange
                          : Colors.grey),
            ],
          ),
          const SizedBox(height: 8),
          Text(example.description,
              style: TextStyle(
                  fontSize: 12.5, color: Colors.grey.shade700, height: 1.35)),
          if (hasResult) ...[
            const SizedBox(height: 8),
            Text(result!.message,
                style: TextStyle(
                    fontSize: 11.5,
                    color: ok ? Colors.green.shade700 : Colors.red.shade700)),
          ],
          if (!ok && hasResult && (result!.stackTrace ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            SelectableText(
              result.stackTrace!,
              maxLines: 4,
              style: const TextStyle(
                  fontSize: 10.5,
                  fontFamily: 'Consolas',
                  color: Colors.redAccent),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton(
                onPressed: () => _loadExample(example),
                child: const Text('Load'),
              ),
              TextButton(
                onPressed: () => _testExample(example),
                child: const Text('Test'),
              ),
              TextButton(
                onPressed: () => _removeExample(example.id),
                child: const Text('Remove'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11.5, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  String _errorSignature(Object error, [StackTrace? stackTrace]) {
    return '$error\n${stackTrace?.toString() ?? ''}';
  }

  void _captureRenderError(
    Object error, {
    StackTrace? stackTrace,
    String source = 'render',
  }) {
    final String signature = '$source|${_errorSignature(error, stackTrace)}';
    if (signature == _lastErrorSignature) return;
    _lastErrorSignature = signature;

    if (!mounted) return;
    setState(() {
      _error = error.toString();
      _stackTrace = stackTrace?.toString() ?? '';
      _status = '$source error captured.';
      _blankRenderWarning = '';
    });
  }

  void _handlePreviewSize(Size size) {
    if (!mounted) return;
    final bool isBlank = size.width < 8 || size.height < 8;
    if (size == _lastPreviewSize &&
        ((_blankRenderWarning.isNotEmpty && isBlank) ||
            (_blankRenderWarning.isEmpty && !isBlank))) {
      return;
    }
    _lastPreviewSize = size;
    setState(() {
      if (isBlank && _compiledBlueprint != null && _error.isEmpty) {
        _blankRenderWarning =
            'Blank render detected: preview size is ${size.width.toStringAsFixed(1)} × ${size.height.toStringAsFixed(1)}.';
      } else if (!isBlank) {
        _blankRenderWarning = '';
      }
    });
  }

  Future<void> _copyLastError() async {
    final combined = _stackTrace.isEmpty ? _error : '$_error\n\n$_stackTrace';
    await Clipboard.setData(ClipboardData(text: combined));
    _toast('Error copied to clipboard.', isError: true);
  }
}

class _MeasureSize extends SingleChildRenderObjectWidget {
  final ValueChanged<Size> onChange;

  const _MeasureSize({required this.onChange, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _MeasureSizeRenderObject(onChange);

  @override
  void updateRenderObject(
      BuildContext context, covariant _MeasureSizeRenderObject renderObject) {
    renderObject.onChange = onChange;
  }
}

class _MeasureSizeRenderObject extends RenderProxyBox {
  ValueChanged<Size> onChange;
  Size? _lastSize;

  _MeasureSizeRenderObject(this.onChange);

  @override
  void performLayout() {
    super.performLayout();
    if (_lastSize == size) return;
    _lastSize = size;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (attached) onChange(size);
    });
  }
}

class _StudioExample {
  final String id;
  final String title;
  final String category;
  final String description;
  final String json;

  const _StudioExample({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.json,
  });
}

class _ExampleHealthResult {
  final String exampleId;
  final bool ok;
  final bool hasRun;
  final String message;
  final String? stackTrace;
  final Duration duration;
  final QLBlueprint? compiledBlueprint;

  const _ExampleHealthResult({
    required this.exampleId,
    required this.ok,
    required this.message,
    required this.duration,
    this.stackTrace,
    this.compiledBlueprint,
    this.hasRun = true,
  });

  factory _ExampleHealthResult.pending(String exampleId) {
    return _ExampleHealthResult(
      exampleId: exampleId,
      ok: false,
      hasRun: false,
      message: 'Not tested yet.',
      duration: Duration.zero,
    );
  }
}

class _LineNumberGutter extends StatelessWidget {
  final TextEditingController controller;

  const _LineNumberGutter({required this.controller});

  @override
  Widget build(BuildContext context) {
    final lineCount = controller.text.isEmpty
        ? 1
        : '\n'.allMatches(controller.text).length + 1;

    return ListView.builder(
      padding: const EdgeInsets.only(top: 20, bottom: 20),
      itemCount: lineCount < 4 ? 4 : lineCount + 4,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            '${index + 1}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white24,
              fontSize: 12,
              fontFamily: 'Consolas',
            ),
          ),
        );
      },
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
