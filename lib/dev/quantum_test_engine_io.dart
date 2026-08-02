// ════════════════════════════════════════════════════════════════════════════
// QUANTUM TEST ENGINE — IO implementation
// src/runtime/quantum_test_engine_io.dart
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:io';
import 'package:yaml/yaml.dart';
import 'quantum_test_engine_shared.dart';
final class QuantumTestEngine {
  static final QuantumTestEngine instance = QuantumTestEngine._();
  QuantumTestEngine._();

  Future<List<QuantumTestManifest>> discoverManifests(
      {String rootPath = 'lib/docs_tests/yaml/by-file'}) async {
    final dir = _resolveExistingDirectory(rootPath);
    if (!dir.existsSync()) {
      throw StateError('Manifest directory not found: $rootPath');
    }

    final manifests = <QuantumTestManifest>[];
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.yaml')) continue;
      if (entity.path.endsWith('INDEX.yaml') ||
          entity.path.endsWith('README.md')) continue;
      manifests.add(loadManifestSync(entity.path));
    }
    manifests.sort((a, b) => a.manifestPath.compareTo(b.manifestPath));
    return manifests;
  }

  QuantumTestManifest loadManifestSync(String manifestPath) {
    final file = _resolveExistingFile(manifestPath);
    if (!file.existsSync()) {
      throw StateError('Manifest not found: $manifestPath');
    }
    final text = file.readAsStringSync();
    final parsed = loadYaml(text);
    final native = _nativeYaml(parsed);
    if (native is! Map<String, dynamic>) {
      throw StateError('Manifest root must be a mapping: $manifestPath');
    }
    return QuantumTestManifest.fromJson(native, manifestPath: manifestPath);
  }

  Future<QuantumTestReport> run({
    String rootPath = 'lib/docs_tests/yaml/by-file',
    required QuantumTestExecutor executor,
    Map<String, dynamic> env = const <String, dynamic>{},
    bool strict = true,
  }) async {
    final started = DateTime.now();
    final manifests = await discoverManifests(rootPath: rootPath);
    final results = <QuantumTestResult>[];
    final issues = <QuantumTestIssue>[];

    for (final manifest in manifests) {
      String sourceText = '';
      final sourceFile = _resolveExistingFile(manifest.sourcePath);
      if (sourceFile.existsSync()) {
        sourceText = sourceFile.readAsStringSync();
      } else {
        issues.add(QuantumTestIssue.error(
            'source.file', 'Source file missing: ${manifest.sourcePath}'));
      }
      final manifestIssues =
          manifest.validate(sourceText: sourceText, strict: strict);
      issues.addAll(manifestIssues);

      for (var gi = 0; gi < manifest.groups.length; gi++) {
        final group = manifest.groups[gi];
        for (var ri = 0; ri < group.rows.length; ri++) {
          final row = group.rows[ri];
          final spec = QuantumTestCaseSpec(
            manifestPath: manifest.manifestPath,
            manifest: manifest,
            group: group,
            row: row,
            groupIndex: gi,
            rowIndex: ri,
            uniqueId: '${manifest.file}::${group.name}::${row.id}',
          );
          final context =
              QuantumTestContext(manifest: manifest, spec: spec, env: env);
          if (!row.isRunnable) {
            results.add(_skipResult(
                spec, row.skipReason ?? 'Row is not runnable.', Duration.zero));
            continue;
          }
          try {
            results.add(await executor(spec, context));
          } catch (e, st) {
            results.add(QuantumTestResult(
              uniqueId: spec.uniqueId,
              manifestPath: manifest.manifestPath,
              filePath: manifest.sourcePath,
              group: group.name,
              row: row.id,
              status: QuantumTestStatus.error,
              phase: QuantumTestPhase.act,
              summary: 'Executor threw an exception.',
              expected: row.expected,
              actual: '',
              error: e.toString(),
              stackTrace: st.toString(),
              duration: Duration.zero,
              details: <String, dynamic>{
                'purpose': row.purpose,
                'input': row.input,
              },
            ));
          }
        }
      }
    }

    final finished = DateTime.now();
    return QuantumTestReport(
      rootPath: rootPath,
      startedAt: started,
      finishedAt: finished,
      results: results,
      issues: issues,
    );
  }

  List<QuantumTestIssue> validateManifest(QuantumTestManifest manifest,
      {String? sourceText, bool strict = true}) {
    return manifest.validate(sourceText: sourceText, strict: strict);
  }

  Future<void> writeRuntimeReportBundle(
    QuantumTestReport report, {
    required String outputRoot,
    bool compact = true,
  }) async {
    return _writeRuntimeReportBundle(
      report,
      outputRoot: outputRoot,
      compact: compact,
    );
  }
}

Future<void> _writeRuntimeReportBundle(
  QuantumTestReport report, {
  required String outputRoot,
  bool compact = true,
}) async {
  final outputDir = Directory(outputRoot);
  outputDir.createSync(recursive: true);

  final grouped = <String, List<QuantumTestResult>>{};
  for (final result in report.results) {
    grouped.putIfAbsent(result.filePath, () => <QuantumTestResult>[]).add(result);
  }

  for (final entry in grouped.entries) {
    final filePath = entry.key;
    final results = entry.value;
    final passResults = results.where((r) => r.ok).toList(growable: false);
    final failResults = results.where((r) => !r.ok).toList(growable: false);
    final summaryMap = <String, dynamic>{
      'filePath': filePath,
      'rootPath': report.rootPath,
      'startedAt': report.startedAt.toIso8601String(),
      'finishedAt': report.finishedAt.toIso8601String(),
      'durationMs': report.duration.inMilliseconds,
      'total': results.length,
      'passed': passResults.length,
      'failed': failResults.length,
      'issues': report.issues.map((e) => e.toJson()).toList(growable: false),
    };

    _writeYamlFile(
      File('${outputDir.path}/pass/$filePath.yaml'),
      <String, dynamic>{
        'filePath': filePath,
        'results': passResults
            .map((e) => e.toJson(compact: compact))
            .toList(growable: false),
      },
    );
    _writeYamlFile(
      File('${outputDir.path}/fail/$filePath.yaml'),
      <String, dynamic>{
        'filePath': filePath,
        'results': failResults
            .map((e) => e.toJson(compact: compact))
            .toList(growable: false),
      },
    );
    _writeYamlFile(
      File('${outputDir.path}/summary/$filePath.yaml'),
      summaryMap,
    );
  }
}

QuantumTestResult _skipResult(
    QuantumTestCaseSpec spec, String reason, Duration duration) {
    return QuantumTestResult(
      uniqueId: spec.uniqueId,
      manifestPath: spec.manifestPath,
      filePath: spec.manifest.sourcePath,
      group: spec.group.name,
      row: spec.row.id,
      status: QuantumTestStatus.skip,
      phase: QuantumTestPhase.summarize,
      summary: reason,
      expected: spec.row.expected,
      actual: '',
      duration: duration,
      details: <String, dynamic>{'skipReason': reason},
    );
  }

Directory _resolveExistingDirectory(String path) {
  final dir = Directory(path);
  if (dir.isAbsolute) {
    return dir;
  }

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
    final dir = Directory(candidate);
    if (dir.existsSync()) return dir;
  }
  return Directory(path);
}

File _resolveExistingFile(String path) {
  final file = File(path);
  if (file.isAbsolute) {
    return file;
  }

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
    final file = File(candidate);
    if (file.existsSync()) return file;
  }
  return File(path);
}

dynamic _nativeYaml(dynamic value) {
  if (value is YamlMap) {
    final map = <String, dynamic>{};
    for (final entry in value.entries) {
      map[entry.key.toString()] = _nativeYaml(entry.value);
    }
    return map;
  }
  if (value is YamlList) {
    return value.map(_nativeYaml).toList(growable: false);
  }
  return value;
}


void _writeYamlFile(File file, Object? value) {
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(_toYaml(value));
}

String _toYaml(Object? value, {int indent = 0}) {
  final buffer = StringBuffer();
  _emitYaml(buffer, value, indent);
  return buffer.toString();
}

void _emitYaml(StringBuffer buffer, Object? value, int indent) {
  final pad = '  ' * indent;
  if (value == null) {
    buffer.writeln('${pad}null');
    return;
  }
  if (value is bool || value is num) {
    buffer.writeln('$pad$value');
    return;
  }
  if (value is String) {
    if (value.contains('\n')) {
      buffer.writeln('${pad}|');
      for (final line in value.split('\n')) {
        buffer.writeln('${pad}  $line');
      }
      return;
    }
    buffer.writeln('$pad${_yamlQuote(value)}');
    return;
  }
  if (value is List) {
    if (value.isEmpty) {
      buffer.writeln('${pad}[]');
      return;
    }
    for (final item in value) {
      buffer.write('$pad- ');
      if (item is Map || item is List) {
        if (item is Map && item.isEmpty) {
          buffer.writeln('{}');
        } else if (item is List && item.isEmpty) {
          buffer.writeln('[]');
        } else {
          buffer.writeln();
          _emitYaml(buffer, item, indent + 1);
        }
      } else {
        _emitYaml(buffer, item, 0);
      }
    }
    return;
  }
  if (value is Map) {
    if (value.isEmpty) {
      buffer.writeln('${pad}{}');
      return;
    }
    for (final entry in value.entries) {
      final key = entry.key.toString();
      final item = entry.value;
      if (item is Map || item is List) {
        if ((item is Map && item.isEmpty) || (item is List && item.isEmpty)) {
          buffer.writeln('$pad${_yamlQuote(key)}: ${item is Map ? '{}' : '[]'}');
        } else {
          buffer.writeln('$pad${_yamlQuote(key)}:');
          _emitYaml(buffer, item, indent + 1);
        }
      } else {
        final out = StringBuffer();
        _emitYaml(out, item, 0);
        final scalar = out.toString().trimRight();
        buffer.writeln('$pad${_yamlQuote(key)}: $scalar');
      }
    }
    return;
  }
  buffer.writeln('$pad${_yamlQuote(value.toString())}');
}

String _yamlQuote(String value) => "'${value.replaceAll("'", "''")}'";
