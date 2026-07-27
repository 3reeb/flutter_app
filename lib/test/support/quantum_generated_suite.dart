// ════════════════════════════════════════════════════════════════════════════
// QUANTUM GENERATED TEST SUPPORT
// test/support/quantum_generated_suite.dart
// ════════════════════════════════════════════════════════════════════════════

import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/src/runtime/quantum_test_engine_io.dart';
import 'package:quantum_layout/src/runtime/quantum_test_engine_shared.dart';
void defineQuantumManifestSuite({
  required String manifestPath,
  required String sourcePath,
  required String fileLabel,
}) {
  final manifest = QuantumTestEngine.instance.loadManifestSync(manifestPath);
  final sourceFile = _resolveExistingFile(sourcePath);
  final sourceText =
      sourceFile.existsSync() ? sourceFile.readAsStringSync() : '';
  final issues = QuantumTestEngine.instance.validateManifest(
    manifest,
    sourceText: sourceText,
    strict: true,
  );

  group(fileLabel, () {
    test('manifest is present and structurally valid', () {
      expect(manifest.file, isNotEmpty);
      expect(manifest.sourcePath, equals(sourcePath));
      expect(manifest.groupCount, greaterThanOrEqualTo(1));
      expect(manifest.rowCount, greaterThanOrEqualTo(manifest.groupCount));
      expect(sourceFile.existsSync(), isTrue,
          reason: 'Source file missing: $sourcePath');
      expect(issues, isEmpty, reason: _compactIssues(issues));
    });

    test('manifest metadata round-trips through JSON', () {
      final clone = QuantumTestManifest.fromJson(
        manifest.toJson(),
        manifestPath: manifest.manifestPath,
      );
      expect(clone.toJson(), equals(manifest.toJson()));
      expect(clone.manifestPath, equals(manifest.manifestPath));
      expect(clone.sourceMetadata.toJson(),
          equals(manifest.sourceMetadata.toJson()));
    });

    test('source metadata is coherent', () {
      expect(manifest.sourceMetadata.path, equals(sourcePath));
      expect(manifest.sourceMetadata.lineCount, greaterThan(0));
      expect(manifest.sourceMetadata.sha256, isNotEmpty);
      expect(manifest.sourceMetadata.category, isNotEmpty);
      expect(manifest.sourceMetadata.profile, isNotEmpty);
      expect(manifest.focus, isNotEmpty);
      expect(manifest.testDocStatus, isNotEmpty);
    });

    test('declared surface names are present in source text', () {
      for (final symbol in manifest.surfaceNames()) {
        expect(sourceText.contains(symbol), isTrue,
            reason: 'Missing symbol in $sourcePath: $symbol');
      }
    });

    test('target symbols are covered by the declared surface list', () {
      final surfaces = manifest.surfaceNames().toSet();
      for (final group in manifest.groups) {
        for (final row in group.rows) {
          for (final symbol in row.targetSymbols) {
            expect(surfaces.contains(symbol), isTrue,
                reason: 'Undeclared target symbol in ${row.id}: $symbol');
            expect(sourceText.contains(symbol), isTrue,
                reason:
                    'Target symbol not found in source text for ${row.id}: $symbol');
          }
        }
      }
    });

    test('declared imports are present in source text', () {
      for (final imp in manifest.sourceMetadata.imports) {
        if (imp.trim().isEmpty) continue;
        expect(sourceText.contains(imp), isTrue,
            reason: 'Missing import in $sourcePath: $imp');
      }
    });

    test('manifest groups and rows are unique', () {
      final groupNames = <String>{};
      final rowIds = <String>{};
      for (final group in manifest.groups) {
        expect(groupNames.add(group.name), isTrue,
            reason: 'Duplicate group: ${group.name}');
        for (final row in group.rows) {
          expect(rowIds.add(row.id), isTrue,
              reason: 'Duplicate row id: ${row.id}');
        }
      }
    });

    test('manifest validation remains stable after JSON round-trip', () {
      final roundTripped = QuantumTestManifest.fromJson(
        manifest.toJson(),
        manifestPath: manifest.manifestPath,
      );
      final roundTripIssues = QuantumTestEngine.instance.validateManifest(
        roundTripped,
        sourceText: sourceText,
        strict: true,
      );
      expect(roundTripIssues, isEmpty, reason: _compactIssues(roundTripIssues));
    });

    for (var gi = 0; gi < manifest.groups.length; gi++) {
      final _group = manifest.groups[gi];
      group('group ${_group.name}', () {
        test('group has a description and rows', () {
          expect(_group.description, isNotNull);
          expect(_group.rows, isNotEmpty);
        });

        test('group references at least one surface', () {
          expect(
              _group.rows.any((row) => row.targetSymbols.isNotEmpty), isTrue);
        });

        for (var ri = 0; ri < _group.rows.length; ri++) {
          final row = _group.rows[ri];
          test('row ${row.id} spec is complete', () {
            expect(row.id, isNotEmpty);
            expect(row.purpose, isNotEmpty);
            expect(row.targetSymbols, isNotEmpty);
            expect(row.setup, isNotEmpty);
            expect(row.input, isNotEmpty);
            expect(row.body, isNotEmpty);
            expect(row.expected, isNotEmpty);
            expect(row.assertions, isNotEmpty);
            expect(row.metrics, isNotEmpty);
            expect(row.risks, isNotEmpty);
            expect(row.cleanup, isNotEmpty);
            expect(row.tags, isNotEmpty);
            expect(row.raw, isNotEmpty);
          });

          test('row ${row.id} target symbols exist in source text', () {
            for (final symbol in row.targetSymbols) {
              expect(sourceText.contains(symbol), isTrue,
                  reason: 'Missing target symbol in $sourcePath: $symbol');
            }
          });
        }
      });
    }
  });
}

void defineQuantumSourceFingerprintSuite({
  required String manifestPath,
  required String sourcePath,
  required String fileLabel,
}) {
  final manifest = QuantumTestEngine.instance.loadManifestSync(manifestPath);
  final sourceFile = _resolveExistingFile(sourcePath);
  final sourceBytes =
      sourceFile.existsSync() ? sourceFile.readAsBytesSync() : <int>[];
  final sourceText =
      sourceFile.existsSync() ? sourceFile.readAsStringSync() : '';
  final issues = QuantumTestEngine.instance.validateManifest(
    manifest,
    sourceText: sourceText,
    strict: true,
  );

  group('$fileLabel · source fingerprint', () {
    test('source hash and line count match the manifest metadata', () {
      expect(sourceFile.existsSync(), isTrue,
          reason: 'Source file missing: $sourcePath');
      expect(sha256.convert(sourceBytes).toString(),
          equals(manifest.sourceMetadata.sha256));
      expect(sourceBytes.where((b) => b == 0x0A).length + 1,
          equals(manifest.sourceMetadata.lineCount));
    });

    test('supplement manifests are loadable and point to the same source', () {
      for (final supplement in manifest.supplements) {
        final supplementManifest =
            QuantumTestEngine.instance.loadManifestSync(supplement.path);
        final supplementIssues = QuantumTestEngine.instance.validateManifest(
          supplementManifest,
          sourceText: sourceText,
          strict: true,
        );
        expect(supplementManifest.sourcePath, equals(sourcePath));
        expect(supplementManifest.file, equals(manifest.file));
        expect(supplementManifest.groupCount, greaterThanOrEqualTo(1));
        expect(supplementIssues, isEmpty,
            reason: _compactIssues(supplementIssues));
      }
    });

    test(
        'manifest validation stays clean when fingerprinted against the source',
        () {
      expect(issues, isEmpty, reason: _compactIssues(issues));
    });
  });
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
    final candidateFile = File(candidate);
    if (candidateFile.existsSync()) return candidateFile;
  }
  return file;
}

Directory _resolveExistingDirectory(String path) {
  final dir = Directory(path);
  if (dir.isAbsolute) {
    return dir;
  }

  final candidates = <String>{path};
  final cwd = Directory.current;
  final dirs = <Directory>[cwd, cwd.parent, cwd.parent.parent];
  for (final d in dirs) {
    candidates.add(d.uri.resolveUri(Uri.file(path)).toFilePath());
  }

  if (path.startsWith('lib/')) {
    final stripped = path.substring(4);
    candidates.add(stripped);
    for (final d in dirs) {
      candidates.add(d.uri.resolveUri(Uri.file(stripped)).toFilePath());
    }
  }

  for (final candidate in candidates) {
    final candidateDir = Directory(candidate);
    if (candidateDir.existsSync()) return candidateDir;
  }
  return dir;
}

String _compactIssues(List issues) {
  if (issues.isEmpty) return 'no issues';
  final items = issues.take(12).map((e) => e.toString()).join(' | ');
  return issues.length > 12 ? '$items | … (${issues.length - 12} more)' : items;
}
