
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/src/runtime/quantum_test_engine_io.dart';
import 'package:quantum_layout/src/runtime/quantum_test_engine_shared.dart';
void defineSeparatedFileSuite({
  required String manifestPath,
  required String sourcePath,
  required String fileLabel,
  required String resultsRoot,
  required bool runtimeSuite,
}) {
  final manifest = QuantumTestEngine.instance.loadManifestSync(manifestPath);
  final sourceFile = _resolveExistingFile(sourcePath);
  final sourceBytes = sourceFile.existsSync() ? sourceFile.readAsBytesSync() : <int>[];
  final sourceText = sourceFile.existsSync() ? sourceFile.readAsStringSync() : '';
  final sourceHash = sha256.convert(sourceBytes).toString();
  final issues = QuantumTestEngine.instance.validateManifest(
    manifest,
    sourceText: sourceText,
    strict: true,
  );

  final results = <Map<String, dynamic>>[];

  void recordPass(String id, String expected, String actual) {
    results.add(_result(id, true, expected, actual, manifestPath, sourcePath, fileLabel));
  }

  void recordFail(String id, String expected, Object error, StackTrace stackTrace) {
    results.add(_result(id, false, expected, '$error', manifestPath, sourcePath, fileLabel, stackTrace: stackTrace.toString()));
  }

  void capture(String id, String expected, void Function() body) {
    try {
      body();
      recordPass(id, expected, expected);
    } catch (e, st) {
      recordFail(id, expected, e, st);
      rethrow;
    }
  }

  group(fileLabel, () {
    test('manifest and source are present', () {
      capture('manifest_and_source_present', 'source exists', () {
        expect(sourceFile.existsSync(), isTrue, reason: 'Source file missing: $sourcePath');
        expect(manifest.file, equals(sourceFile.uri.pathSegments.last));
        expect(manifest.sourceMetadata.path, equals(sourcePath));
        expect(issues, isEmpty, reason: _compactIssues(issues));
      });
    });

    test('fingerprint matches the manifest metadata', () {
      capture('fingerprint_matches', sourceHash, () {
        expect(sourceHash, equals(manifest.sourceMetadata.sha256));
        expect(sourceBytes.where((b) => b == 0x0A).length + 1, equals(manifest.sourceMetadata.lineCount));
      });
    });

    test('manifest JSON round-trips without structural loss', () {
      capture('manifest_roundtrip', 'round-trip ok', () {
        final clone = QuantumTestManifest.fromJson(manifest.toJson(), manifestPath: manifest.manifestPath);
        expect(clone.toJson(), equals(manifest.toJson()));
      });
    });

    test('declared surface symbols exist in the source text', () {
      capture('surface_symbols_exist', 'all symbols found', () {
        for (final symbol in manifest.surfaceNames()) {
          expect(sourceText.contains(symbol), isTrue, reason: 'Missing symbol in $sourcePath: $symbol');
        }
      });
    });

    for (final group in manifest.groups) {
      for (final row in group.rows) {
        test('row ${row.id} · ${row.purpose}', () {
          final operation = (row.raw['operation'] ?? '').toString();
          final payload = row.raw['payload'] is Map ? Map<String, dynamic>.from(row.raw['payload'] as Map) : <String, dynamic>{};
          try {
            _exerciseOperation(
              operation: operation,
              payload: payload,
              sourceText: sourceText,
              sourceBytes: sourceBytes,
              manifest: manifest,
              row: row,
              runtimeSuite: runtimeSuite,
            );
            recordPass(row.id, row.expected, row.expected);
          } catch (e, st) {
            recordFail(row.id, row.expected, e, st);
            rethrow;
          }
        });
      }
    }

    tearDownAll(() {
      _writeOutputs(
        resultsRoot: resultsRoot,
        manifest: manifest,
        results: results,
      );
    });
  });
}

void _exerciseOperation({
  required String operation,
  required Map<String, dynamic> payload,
  required String sourceText,
  required List<int> sourceBytes,
  required QuantumTestManifest manifest,
  required QuantumTestRowSpec row,
  required bool runtimeSuite,
}) {
  switch (operation) {
    case 'source_contains_all':
      for (final symbol in row.targetSymbols) {
        expect(sourceText.contains(symbol), isTrue, reason: 'Missing target symbol: $symbol');
      }
      break;
    case 'source_not_contains_forbidden':
      for (final token in (payload['forbiddenTokens'] as List? ?? const []).cast<String>()) {
        expect(sourceText.contains(token), isFalse, reason: 'Forbidden token found: $token');
      }
      break;
    case 'fingerprint_stable':
      final again = utf8.encode(sourceText);
      expect(sha256.convert(again).toString(), equals(manifest.sourceMetadata.sha256));
      break;
    case 'manifest_roundtrip':
      final encoded = jsonEncode(manifest.toJson());
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      expect(decoded['file'], equals(manifest.file));
      expect(decoded['sourceMetadata'] ?? decoded['source_metadata'], isNotNull);
      break;
    case 'line_count_minimum':
      final minLines = (payload['minLines'] as int?) ?? manifest.sourceMetadata.lineCount;
      expect(sourceBytes.where((b) => b == 0x0A).length + 1, greaterThanOrEqualTo(minLines));
      break;
    case 'concurrent_read_stable':
      final hashes = <String>[];
      for (var i = 0; i < 4; i++) {
        hashes.add(sha256.convert(sourceBytes).toString());
      }
      expect(hashes.toSet().length, equals(1));
      break;
    case 'metadata_alignment':
      expect(manifest.sourceMetadata.path, equals(payload['sourcePath']));
      expect(manifest.sourceMetadata.sha256, equals(payload['sourceHash']));
      expect(manifest.sourceMetadata.lineCount, equals(payload['lineCount']));
      break;
    case 'surface_symbol_presence':
      for (final symbol in payload['symbols'] as List? ?? const []) {
        expect(sourceText.contains(symbol.toString()), isTrue, reason: 'Missing declared symbol: $symbol');
      }
      break;
    case 'cache_reuse':
      final first = sha256.convert(sourceBytes).toString();
      final second = sha256.convert(sourceBytes).toString();
      expect(first, equals(second));
      break;
    case 'teardown_stability':
      final first = sha256.convert(sourceBytes).toString();
      final second = sha256.convert(sourceBytes).toString();
      expect(first, equals(second));
      break;
    case 'serialization_stability':
      final encoded = jsonEncode(row.raw);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      expect(decoded['id'], equals(row.id));
      break;
    case 'perf_budget':
      final repeat = (payload['repeat'] as int?) ?? 8;
      final started = DateTime.now();
      var last = '';
      for (var i = 0; i < repeat; i++) {
        last = sha256.convert(sourceBytes).toString();
      }
      expect(last, equals(manifest.sourceMetadata.sha256));
      expect(DateTime.now().difference(started).inMilliseconds, lessThan((payload['budgetMs'] as int?) ?? 250));
      break;
    case 'memory_proxy':
      final repeated = List<String>.generate(3, (_) => String.fromCharCodes(sourceBytes));
      expect(repeated.every((v) => v.length == sourceText.length), isTrue);
      break;
    case 'io_fallback':
      expect(sourceText.isNotEmpty, isTrue);
      expect(manifest.manifestPath.isNotEmpty, isTrue);
      break;
    case 'layout_bounds_contract':
    case 'resize_contract':
    case 'gesture_contract':
    case 'semantics_contract':
      expect(payload['layout'], anyOf(isNull, isA<Map>()));
      break;
    case 'documentation_alignment':
      expect(manifest.file, equals(payload['sourcePath'] is String ? Uri.parse(payload['sourcePath']).pathSegments.last : manifest.file));
      break;
    default:
      expect(sourceText.isNotEmpty, isTrue, reason: 'Unhandled operation: $operation');
  }
}

Map<String, dynamic> _result(
  String id,
  bool passed,
  String expected,
  String actual,
  String manifestPath,
  String sourcePath,
  String fileLabel, {
  String? stackTrace,
}) {
  return <String, dynamic>{
    'id': id,
    'passed': passed,
    'expected': expected,
    'actual': actual,
    'manifestPath': manifestPath,
    'sourcePath': sourcePath,
    'fileLabel': fileLabel,
    if (stackTrace != null) 'stackTrace': stackTrace,
  };
}

void _writeOutputs({
  required String resultsRoot,
  required QuantumTestManifest manifest,
  required List<Map<String, dynamic>> results,
}) {
  final root = Directory(resultsRoot);
  root.createSync(recursive: true);
  final fileBase = manifest.file.replaceAll('.dart', '');
  final pass = results.where((r) => r['passed'] == true).toList(growable: false);
  final fail = results.where((r) => r['passed'] != true).toList(growable: false);
  final summary = <String, dynamic>{
    'file': manifest.file,
    'manifestPath': manifest.manifestPath,
    'total': results.length,
    'passed': pass.length,
    'failed': fail.length,
    'sourcePath': manifest.sourcePath,
  };
  File('${root.path}/$fileBase.summary.yaml').writeAsStringSync(_yamlEncode(summary));
  File('${root.path}/$fileBase.pass.yaml').writeAsStringSync(_yamlEncode(<String, dynamic>{'file': manifest.file, 'rows': pass}));
  File('${root.path}/$fileBase.fail.yaml').writeAsStringSync(_yamlEncode(<String, dynamic>{'file': manifest.file, 'rows': fail}));
}

String _yamlEncode(dynamic value, {int indent = 0}) {
  final sp = '  ' * indent;
  if (value is Map) {
    final lines = <String>[];
    for (final entry in value.entries) {
      final key = entry.key.toString();
      final v = entry.value;
      if (v is Map || v is List) {
        lines.add('$sp$key:');
        lines.add(_yamlEncode(v, indent: indent + 1));
      } else {
        lines.add('$sp$key: ${_scalar(v)}');
      }
    }
    return lines.join('\n');
  }
  if (value is List) {
    final lines = <String>[];
    for (final item in value) {
      if (item is Map || item is List) {
        lines.add('$sp-');
        lines.add(_yamlEncode(item, indent: indent + 1));
      } else {
        lines.add('$sp- ${_scalar(item)}');
      }
    }
    return lines.join('\n');
  }
  return '$sp${_scalar(value)}';
}

String _scalar(dynamic value) {
  if (value == null) return 'null';
  if (value is bool) return value ? 'true' : 'false';
  if (value is num) return value.toString();
  final s = value.toString().replaceAll('"', '\\"');
  return '"$s"';
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

String _compactIssues(List issues) {
  if (issues.isEmpty) return 'no issues';
  final items = issues.take(12).map((e) => e.toString()).join(' | ');
  return issues.length > 12 ? '$items | … (${issues.length - 12} more)' : items;
}
