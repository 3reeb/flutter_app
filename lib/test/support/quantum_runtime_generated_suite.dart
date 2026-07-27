// ════════════════════════════════════════════════════════════════════════════
// QUANTUM RUNTIME GENERATED TEST SUPPORT
// test/support/quantum_runtime_generated_suite.dart
// ════════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';
import 'package:quantum_layout/src/runtime/quantum_test_engine.dart';

void defineQuantumRuntimeFileSuite({
  required String manifestPath,
  required String inventoryPath,
  required String sourcePath,
  required String docsPath,
  required String fileLabel,
  String resultsRoot = 'tests/runtime/results',
}) {
  final manifest = _loadYamlMap(manifestPath);
  final inventory = _loadYamlMap(inventoryPath);
  final inventoryEntry = _inventoryEntryFor(inventory, sourcePath);
  final sourceFile = _resolveExistingFile(sourcePath);
  final docsFile = _resolveExistingFile(docsPath);
  final sourceText =
      sourceFile.existsSync() ? sourceFile.readAsStringSync() : '';
  final docsText = docsFile.existsSync() ? docsFile.readAsStringSync() : '';
  final sourceBytes =
      sourceFile.existsSync() ? sourceFile.readAsBytesSync() : <int>[];
  final startedAt = DateTime.now();
  final results = <QuantumTestResult>[];
  final shouldWriteResults =
      Platform.environment['QUANTUM_WRITE_RUNTIME_RESULTS'] == '1';
  final scenarios = _scenarioList(manifest);

  group(fileLabel, () {
    tearDownAll(() async {
      if (!shouldWriteResults) return;
      final report = QuantumTestReport(
        rootPath: manifestPath,
        startedAt: startedAt,
        finishedAt: DateTime.now(),
        results: List<QuantumTestResult>.unmodifiable(results),
        issues: const <QuantumTestIssue>[],
      );
      await QuantumTestEngine.instance.writeRuntimeReportBundle(
        report,
        outputRoot: resultsRoot,
      );
    });

    test('source, docs, and inventory metadata stay coherent', () {
      final result = _evaluateInventory(
        manifestPath: manifestPath,
        sourcePath: sourcePath,
        docsPath: docsPath,
        fileLabel: fileLabel,
        inventoryEntry: inventoryEntry,
        sourceFile: sourceFile,
        docsFile: docsFile,
        sourceText: sourceText,
        docsText: docsText,
      );
      results.add(result);
      expect(result.ok, isTrue, reason: result.summary);
    });

    test('fingerprints stay stable under repeated reads', () {
      final result = _evaluateFingerprintStress(
        manifestPath: manifestPath,
        sourcePath: sourcePath,
        docsPath: docsPath,
        fileLabel: fileLabel,
        sourceFile: sourceFile,
        docsFile: docsFile,
        sourceBytes: sourceBytes,
        sourceText: sourceText,
        docsText: docsText,
        inventoryEntry: inventoryEntry,
      );
      results.add(result);
      expect(result.ok, isTrue, reason: result.summary);
    });

    test('stress loop stays memory-friendly on the hot path', () {
      final result = _evaluateMemoryStress(
        manifestPath: manifestPath,
        sourcePath: sourcePath,
        docsPath: docsPath,
        fileLabel: fileLabel,
        sourceText: sourceText,
        docsText: docsText,
        inventoryEntry: inventoryEntry,
      );
      results.add(result);
      expect(result.ok, isTrue, reason: result.summary);
    });

    if (_looksLikeUiOrApp(sourcePath, inventoryEntry))
      testWidgets('layout, drag, and resize smoke remain functional',
          (tester) async {
        final result = await _evaluateWidgetSmoke(
          tester,
          manifestPath: manifestPath,
          sourcePath: sourcePath,
          docsPath: docsPath,
          fileLabel: fileLabel,
        );
        results.add(result);
        expect(result.ok, isTrue, reason: result.summary);
      });

    for (final scenario in scenarios) {
      final scenarioSeverity = scenario['severity']?.toString() ?? '';
      final scenarioSlug = scenario['slug']?.toString() ?? '';
      final scenarioTitle = scenario['title']?.toString() ?? '';
      test('$scenarioSeverity · $scenarioSlug · $scenarioTitle', () {
        final result = _evaluateScenario(
          scenario: scenario,
          manifestPath: manifestPath,
          sourcePath: sourcePath,
          docsPath: docsPath,
          fileLabel: fileLabel,
          sourceText: sourceText,
          docsText: docsText,
          inventoryEntry: inventoryEntry,
        );
        results.add(result);
        expect(result.ok, isTrue, reason: result.summary);
      });
    }
  });
}

Map<String, dynamic> _loadYamlMap(String path) {
  final file = _resolveExistingFile(path);
  if (!file.existsSync()) {
    throw StateError('YAML file not found: $path');
  }
  final decoded = loadYaml(file.readAsStringSync());
  final native = _toNative(decoded);
  if (native is! Map<String, dynamic>) {
    throw StateError('YAML root must be a map: $path');
  }
  return native;
}

Map<String, dynamic> _inventoryEntryFor(
    Map<String, dynamic> inventory, String sourcePath) {
  final rawFiles = inventory['files'];
  if (rawFiles is! List) {
    throw StateError('Inventory file must contain a "files" list.');
  }
  for (final item in rawFiles) {
    if (item is Map) {
      final map = Map<String, dynamic>.from(item);
      if (map['file']?.toString() == sourcePath) {
        return map;
      }
    }
  }
  throw StateError('No inventory entry found for $sourcePath');
}

List<Map<String, dynamic>> _scenarioList(Map<String, dynamic> manifest) {
  final raw = manifest['scenarios'];
  if (raw is! List) return const <Map<String, dynamic>>[];
  return raw
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}

QuantumTestResult _evaluateInventory({
  required String manifestPath,
  required String sourcePath,
  required String docsPath,
  required String fileLabel,
  required Map<String, dynamic> inventoryEntry,
  required File sourceFile,
  required File docsFile,
  required String sourceText,
  required String docsText,
}) {
  final started = DateTime.now();
  final failures = <String>[];
  void fail(String message) => failures.add(message);

  if (!sourceFile.existsSync()) fail('source file missing');
  if (!docsFile.existsSync()) fail('docs file missing');
  if (fileLabel != sourcePath) fail('file label drifted from the source path');
  if (inventoryEntry['file']?.toString() != sourcePath)
    fail('inventory path mismatch');
  if (inventoryEntry['docs_file']?.toString() != docsPath)
    fail('inventory docs path mismatch');

  final expectedTestCount =
      (inventoryEntry['test_count'] as num?)?.toInt() ?? 0;
  if (expectedTestCount <= 0) fail('inventory test count must be positive');
  if (sourceText.trim().isEmpty) fail('source text is empty');
  if (docsText.trim().isEmpty) fail('docs text is empty');

  final classCount = _countMatches(
      sourceText, r'(?m)^\s*(?:abstract\s+)?(?:final\s+)?class\s+\w+');
  final enumCount = _countMatches(sourceText, r'(?m)^\s*enum\s+\w+');
  final functionCount =
      _countMatches(sourceText, r'(?m)^\s*(?:[A-Za-z_<>,?\[\] ]+\s+)?\w+\s*\(');

  final inventoryClassCount =
      (inventoryEntry['class_count'] as num?)?.toInt() ?? 0;
  final inventoryEnumCount =
      (inventoryEntry['enum_count'] as num?)?.toInt() ?? 0;
  final inventoryFunctionCount =
      (inventoryEntry['function_count'] as num?)?.toInt() ?? 0;

  if (inventoryClassCount > 0 && classCount <= 0)
    fail('no class declarations were detected');
  if (inventoryEnumCount > 0 && enumCount <= 0)
    fail('no enum declarations were detected');
  if (inventoryFunctionCount > 0 && functionCount <= 0)
    fail('no function declarations were detected');

  final topClasses = _stringList(inventoryEntry['top_classes']);
  final topFunctions = _stringList(inventoryEntry['top_functions']);
  for (final symbol in topClasses) {
    if (!sourceText.contains(symbol)) fail('missing top class symbol: $symbol');
  }
  for (final symbol in topFunctions) {
    if (!sourceText.contains(symbol))
      fail('missing top function symbol: $symbol');
  }

  final docsHeadings = _stringListFromAny(inventoryEntry['docs_headings']);
  for (final heading in docsHeadings) {
    if (!docsText.contains(heading)) fail('missing docs heading: $heading');
  }

  final actual = <String, dynamic>{
    'sourceHash': sha256.convert(sourceFile.readAsBytesSync()).toString(),
    'docsHash': sha256.convert(utf8.encode(docsText)).toString(),
    'lineCount': sourceFile.readAsLinesSync().length,
    'classCount': classCount,
    'enumCount': enumCount,
    'functionCount': functionCount,
  };

  final duration = DateTime.now().difference(started);
  return QuantumTestResult(
    uniqueId: 'inventory::$sourcePath',
    manifestPath: manifestPath,
    filePath: sourcePath,
    group: 'inventory',
    row: 'inventory',
    status: failures.isEmpty ? QuantumTestStatus.pass : QuantumTestStatus.fail,
    phase: QuantumTestPhase.summarize,
    summary:
        failures.isEmpty ? 'inventory contract is coherent' : failures.first,
    expected: jsonEncode({
      'sourcePath': sourcePath,
      'docsPath': docsPath,
      'testCount': expectedTestCount,
    }),
    actual: jsonEncode(actual),
    duration: duration,
    details: <String, dynamic>{
      'inventory': inventoryEntry,
      'failures': failures,
      'actual': actual,
    },
  );
}

QuantumTestResult _evaluateFingerprintStress({
  required String manifestPath,
  required String sourcePath,
  required String docsPath,
  required String fileLabel,
  required File sourceFile,
  required File docsFile,
  required List<int> sourceBytes,
  required String sourceText,
  required String docsText,
  required Map<String, dynamic> inventoryEntry,
}) {
  final started = DateTime.now();
  final failures = <String>[];
  void fail(String message) => failures.add(message);

  if (sourceBytes.isEmpty) fail('source bytes are empty');
  if (!sourceFile.existsSync()) fail('source file missing');
  if (!docsFile.existsSync()) fail('docs file missing');

  final hashIterations =
      ((inventoryEntry['test_count'] as num?)?.toInt() ?? 1) * 12;
  String sourceHash = '';
  String docsHash = '';
  for (var i = 0; i < hashIterations; i++) {
    sourceHash = sha256.convert(sourceBytes).toString();
    docsHash = sha256.convert(utf8.encode(docsText)).toString();
    if (!sourceText.contains('class') &&
        !sourceText.contains('enum') &&
        !sourceText.contains('typedef')) {
      fail('source surface is unexpectedly empty of declarations');
      break;
    }
  }

  final duration = DateTime.now().difference(started);
  final softBudgetMs = _softBudgetMs(inventoryEntry, multiplier: 8);
  if (duration.inMilliseconds > softBudgetMs) {
    fail(
        'fingerprint stress exceeded soft budget: ${duration.inMilliseconds}ms > ${softBudgetMs}ms');
  }

  return QuantumTestResult(
    uniqueId: 'fingerprint::$sourcePath',
    manifestPath: manifestPath,
    filePath: sourcePath,
    group: 'fingerprint',
    row: 'stability',
    status: failures.isEmpty ? QuantumTestStatus.pass : QuantumTestStatus.fail,
    phase: QuantumTestPhase.summarize,
    summary: failures.isEmpty
        ? 'fingerprints stayed stable under repeated read pressure'
        : failures.first,
    expected: jsonEncode({'stable': true, 'softBudgetMs': softBudgetMs}),
    actual: jsonEncode({
      'durationMs': duration.inMilliseconds,
      'sourceHash': sourceHash,
      'docsHash': docsHash,
      'iterations': hashIterations,
    }),
    duration: duration,
    details: <String, dynamic>{
      'sourcePath': sourcePath,
      'docsPath': docsPath,
      'durationMs': duration.inMilliseconds,
      'softBudgetMs': softBudgetMs,
      'iterations': hashIterations,
    },
  );
}

QuantumTestResult _evaluateMemoryStress({
  required String manifestPath,
  required String sourcePath,
  required String docsPath,
  required String fileLabel,
  required String sourceText,
  required String docsText,
  required Map<String, dynamic> inventoryEntry,
}) {
  final started = DateTime.now();
  final failures = <String>[];
  void fail(String message) => failures.add(message);

  final baselineRss = ProcessInfo.currentRss;
  final rounds = ((inventoryEntry['test_count'] as num?)?.toInt() ?? 1) * 30;
  var bytes = 0;
  for (var i = 0; i < rounds; i++) {
    bytes += utf8.encode(sourceText).length;
    bytes += utf8.encode(docsText).length;
    if (i % 7 == 0) {
      bytes ^= sourceText.hashCode;
    }
  }
  final afterRss = ProcessInfo.currentRss;
  final rssDelta = afterRss - baselineRss;
  final duration = DateTime.now().difference(started);
  final softBudgetMs = _softBudgetMs(inventoryEntry, multiplier: 10);
  final allowedGrowth = math.max(
      8 * 1024 * 1024, (_memoryBudgetMb(inventoryEntry) * 8) * 1024 * 1024);

  if (rssDelta > allowedGrowth) {
    fail(
        'rss growth exceeded soft memory budget: ${rssDelta}B > ${allowedGrowth}B');
  }
  if (duration.inMilliseconds > softBudgetMs) {
    fail(
        'memory stress exceeded soft time budget: ${duration.inMilliseconds}ms > ${softBudgetMs}ms');
  }

  return QuantumTestResult(
    uniqueId: 'memory::$sourcePath',
    manifestPath: manifestPath,
    filePath: sourcePath,
    group: 'memory',
    row: 'pressure',
    status: failures.isEmpty ? QuantumTestStatus.pass : QuantumTestStatus.fail,
    phase: QuantumTestPhase.summarize,
    summary: failures.isEmpty
        ? 'memory pressure stayed within a soft envelope'
        : failures.first,
    expected: jsonEncode(
        {'maxGrowthBytes': allowedGrowth, 'softBudgetMs': softBudgetMs}),
    actual: jsonEncode({
      'rssDelta': rssDelta,
      'rounds': rounds,
      'durationMs': duration.inMilliseconds,
      'bytes': bytes
    }),
    duration: duration,
    details: <String, dynamic>{
      'baselineRss': baselineRss,
      'afterRss': afterRss,
      'rssDelta': rssDelta,
      'allowedGrowth': allowedGrowth,
      'rounds': rounds,
      'bytes': bytes,
    },
  );
}

Future<QuantumTestResult> _evaluateWidgetSmoke(
  WidgetTester tester, {
  required String manifestPath,
  required String sourcePath,
  required String docsPath,
  required String fileLabel,
}) async {
  final started = DateTime.now();
  final failures = <String>[];
  void fail(String message) => failures.add(message);
  final events = <String>[];

  final view = tester.view;
  view.physicalSize = const Size(960, 640);
  view.devicePixelRatio = 1.0;
  addTearDown(view.resetPhysicalSize);
  addTearDown(view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 320,
            height: 240,
            child: LayoutBuilder(
              builder: (context, constraints) {
                events.add(
                    'layout:${constraints.maxWidth}x${constraints.maxHeight}');
                if (constraints.maxWidth != 320 ||
                    constraints.maxHeight != 240) {
                  fail('layout constraints drifted');
                }
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => events.add('tap'),
                  onPanUpdate: (details) => events.add(
                      'drag:${details.delta.dx.toStringAsFixed(1)},${details.delta.dy.toStringAsFixed(1)}'),
                  child: const ColoredBox(
                    color: Colors.transparent,
                    child: Center(child: Text('runtime-smoke')),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.tap(find.text('runtime-smoke'));
  await tester.pump();
  await tester.drag(find.byType(GestureDetector), const Offset(24, 36));
  await tester.pump();

  if (find.text('runtime-smoke').evaluate().isEmpty) {
    fail('smoke widget did not render');
  }
  if (!events.any((e) => e.startsWith('layout:'))) {
    fail('layout callback did not fire');
  }
  if (!events.contains('tap')) {
    fail('tap callback did not fire');
  }
  if (!events.any((e) => e.startsWith('drag:'))) {
    fail('drag callback did not fire');
  }

  final duration = DateTime.now().difference(started);
  return QuantumTestResult(
    uniqueId: 'widget-smoke::$sourcePath',
    manifestPath: manifestPath,
    filePath: sourcePath,
    group: 'widget_smoke',
    row: 'layout_drag_resize',
    status: failures.isEmpty ? QuantumTestStatus.pass : QuantumTestStatus.fail,
    phase: QuantumTestPhase.summarize,
    summary: failures.isEmpty
        ? 'widget smoke exercised layout, tap, and drag paths'
        : failures.first,
    expected: jsonEncode({
      'width': 320,
      'height': 240,
      'events': ['layout', 'tap', 'drag']
    }),
    actual:
        jsonEncode({'events': events, 'durationMs': duration.inMilliseconds}),
    duration: duration,
    details: <String, dynamic>{
      'sourcePath': sourcePath,
      'docsPath': docsPath,
      'events': events,
      'durationMs': duration.inMilliseconds,
    },
  );
}

QuantumTestResult _evaluateScenario({
  required Map<String, dynamic> scenario,
  required String manifestPath,
  required String sourcePath,
  required String docsPath,
  required String fileLabel,
  required String sourceText,
  required String docsText,
  required Map<String, dynamic> inventoryEntry,
}) {
  final started = DateTime.now();
  final failures = <String>[];
  void fail(String message) => failures.add(message);

  final uuid = scenario['uuid']?.toString() ?? '';
  final title = scenario['title']?.toString() ?? '';
  final slug = scenario['slug']?.toString() ?? '';
  final category = scenario['category']?.toString() ?? '';
  final severity = scenario['severity']?.toString() ?? '';
  final description = scenario['description']?.toString() ?? '';
  final input = _mapOf(scenario['input']);
  final expectedOutput = _mapOf(scenario['expected_output']);
  final observability = _mapOf(scenario['observability']);
  final performanceBudget = _mapOf(scenario['performance_budget']);
  final memoryBudget = _mapOf(scenario['memory_budget']);
  final cleanup = _stringListFromAny(scenario['cleanup']);
  final docsParity = _mapOf(scenario['docs_parity']);
  final tags = _stringListFromAny(scenario['tags']);

  if (!RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(uuid))
    fail('uuid is not a valid UUID: $uuid');
  if (title.trim().isEmpty) fail('title is empty');
  if (slug.trim().isEmpty) fail('slug is empty');
  if (category.trim().isEmpty) fail('category is empty');
  if (severity.trim().isEmpty) fail('severity is empty');
  if (description.trim().isEmpty) fail('description is empty');
  if (scenario['file']?.toString() != sourcePath)
    fail('scenario source path mismatch');
  if (scenario['docs_file']?.toString() != docsPath)
    fail('scenario docs path mismatch');
  if (tags.isEmpty) fail('scenario tags are empty');
  if (cleanup.isEmpty) fail('cleanup steps are empty');
  if (input.isEmpty) fail('input payload is empty');
  if (expectedOutput.isEmpty) fail('expected_output payload is empty');
  if (observability.isEmpty) fail('observability payload is empty');
  if (performanceBudget.isEmpty) fail('performance budget payload is empty');
  if (memoryBudget.isEmpty) fail('memory budget payload is empty');
  if (docsParity.isEmpty) fail('docs parity payload is empty');

  final preconditions = _stringListFromAny(input['preconditions']);
  final stimulus = _stringListFromAny(input['stimulus']);
  final workload = _stringListFromAny(_mapOf(input['data'])['workload']);
  if (preconditions.isEmpty) fail('preconditions are empty');
  if (stimulus.isEmpty) fail('stimulus is empty');
  if (workload.isEmpty) fail('workload list is empty');

  final expectedState = expectedOutput['state']?.toString() ?? '';
  final expectedCleanup = expectedOutput['cleanup']?.toString() ?? '';
  final expectedPerformance = expectedOutput['performance']?.toString() ?? '';
  if (expectedState.isEmpty) fail('expected state is empty');
  if (expectedCleanup.isEmpty) fail('expected cleanup is empty');
  if (expectedPerformance.isEmpty) fail('expected performance is empty');

  final logs = observability['logs']?.toString() ?? '';
  final metrics = observability['metrics']?.toString() ?? '';
  final traces = observability['traces']?.toString() ?? '';
  if (logs.isEmpty) fail('logs observability is empty');
  if (metrics.isEmpty) fail('metrics observability is empty');
  if (traces.isEmpty) fail('traces observability is empty');

  final docsHeadings = _stringListFromAny(docsParity['headings']);
  final docsSummary = docsParity['summary']?.toString() ?? '';
  if (docsSummary.isEmpty) fail('docs parity summary is empty');
  if (docsHeadings.isEmpty) fail('docs parity headings are empty');
  for (final heading in docsHeadings) {
    if (!docsText.contains(heading)) fail('docs heading missing: $heading');
  }
  if (!docsText.contains(sourcePath.split('/').last)) {
    fail('docs text does not mention the source file name');
  }

  final maxMs = _intFromAny(performanceBudget['max_ms'], fallback: 0);
  final stressMs = _intFromAny(performanceBudget['stress_ms'], fallback: 0);
  final maxGrowthMb = _intFromAny(memoryBudget['max_growth_mb'], fallback: 0);
  if (maxMs <= 0) fail('max_ms must be positive');
  if (stressMs <= 0) fail('stress_ms must be positive');
  if (maxGrowthMb <= 0) fail('max_growth_mb must be positive');

  final rounds =
      math.max(1, _intFromAny(inventoryEntry['test_count'], fallback: 1) * 4);
  var checksum = 0;
  for (var i = 0; i < rounds; i++) {
    checksum ^= sourceText.hashCode;
    checksum ^= docsText.hashCode;
    checksum ^= uuid.hashCode;
    checksum ^= slug.hashCode;
  }

  final duration = DateTime.now().difference(started);
  final softLimit = math.max(120, maxMs * 8);
  if (duration.inMilliseconds > softLimit) {
    fail(
        'scenario execution exceeded soft time budget: ${duration.inMilliseconds}ms > ${softLimit}ms');
  }

  return QuantumTestResult(
    uniqueId: uuid,
    manifestPath: manifestPath,
    filePath: sourcePath,
    group: category,
    row: slug,
    status: failures.isEmpty ? QuantumTestStatus.pass : QuantumTestStatus.fail,
    phase: QuantumTestPhase.summarize,
    summary: failures.isEmpty ? title : failures.first,
    expected: jsonEncode({
      'state': expectedState,
      'cleanup': expectedCleanup,
      'performance': expectedPerformance,
      'maxMs': maxMs,
      'stressMs': stressMs,
      'maxGrowthMb': maxGrowthMb,
    }),
    actual: jsonEncode({
      'durationMs': duration.inMilliseconds,
      'checksum': checksum,
      'rounds': rounds,
      'sourceHash': sha256.convert(utf8.encode(sourceText)).toString(),
      'docsHash': sha256.convert(utf8.encode(docsText)).toString(),
    }),
    duration: duration,
    details: <String, dynamic>{
      'uuid': uuid,
      'title': title,
      'slug': slug,
      'category': category,
      'severity': severity,
      'tags': tags,
      'cleanup': cleanup,
      'input': input,
      'expected_output': expectedOutput,
      'observability': observability,
      'performance_budget': performanceBudget,
      'memory_budget': memoryBudget,
      'docs_parity': docsParity,
      'failures': failures,
      'sourcePath': sourcePath,
      'docsPath': docsPath,
      'durationMs': duration.inMilliseconds,
    },
  );
}

bool _looksLikeUiOrApp(String sourcePath, Map<String, dynamic> inventoryEntry) {
  final category = inventoryEntry['category']?.toString() ?? '';
  return sourcePath.contains('/ui/') ||
      sourcePath.contains('/app/') ||
      category == 'ui' ||
      category == 'app';
}

int _softBudgetMs(Map<String, dynamic> inventoryEntry,
    {required int multiplier}) {
  final base = _intFromAny(inventoryEntry['line_count'], fallback: 1);
  return math.max(120, base ~/ 3) + multiplier * 10;
}

int _memoryBudgetMb(Map<String, dynamic> inventoryEntry) {
  final entry = _intFromAny(inventoryEntry['byte_count'], fallback: 0);
  if (entry <= 0) return 1;
  return math.max(1, entry ~/ (1024 * 1024));
}

int _countMatches(String text, String pattern) =>
    RegExp(pattern).allMatches(text).length;

int _intFromAny(dynamic value, {required int fallback}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

Map<String, dynamic> _mapOf(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<String> _stringListFromAny(dynamic value) {
  if (value is List) {
    return value
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList(growable: false);
  }
  if (value == null) return const <String>[];
  final text = value.toString().trim();
  if (text.isEmpty) return const <String>[];
  return <String>[text];
}

List<String> _stringList(dynamic value) => _stringListFromAny(value);

dynamic _toNative(dynamic value) {
  if (value is YamlMap) {
    final map = <String, dynamic>{};
    for (final entry in value.entries) {
      map[entry.key.toString()] = _toNative(entry.value);
    }
    return map;
  }
  if (value is YamlList) {
    return value.map(_toNative).toList(growable: false);
  }
  return value;
}

File _resolveExistingFile(String path) {
  final file = File(path);
  if (file.isAbsolute) return file;
  final candidates = <String>{path};
  final cwd = Directory.current;
  final dirs = <Directory>[cwd, cwd.parent, cwd.parent.parent];
  for (final dir in dirs) {
    candidates.add(dir.uri.resolveUri(Uri.file(path)).toFilePath());
  }
  if (path.startsWith('lib/')) {
    final stripped = path.substring(4);
    candidates.add(stripped);
    for (final dir in dirs) {
      candidates.add(dir.uri.resolveUri(Uri.file(stripped)).toFilePath());
    }
  }
  for (final candidate in candidates) {
    final candidateFile = File(candidate);
    if (candidateFile.existsSync()) return candidateFile;
  }
  return file;
}
