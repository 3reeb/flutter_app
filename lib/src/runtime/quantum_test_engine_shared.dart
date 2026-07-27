
// ════════════════════════════════════════════════════════════════════════════
// QUANTUM TEST ENGINE — shared manifest/result model
// src/runtime/quantum_test_engine_shared.dart
//
// This layer is intentionally pure Dart so it can be reused by generated test
// files, CLI tooling, and runtime analyzers without depending on Flutter UI.
// ════════════════════════════════════════════════════════════════════════════

library quantum_test_engine_shared;

import 'dart:convert';
import 'package:flutter/foundation.dart';
enum QuantumTestStatus { pass, fail, skip, error, warn }

enum QuantumTestPhase { discover, arrange, act, _assert, teardown, summarize }

@immutable
class QuantumTestSourceMetadata {
  final String path;
  final String sha256;
  final int lineCount;
  final List<String> imports;
  final List<String> exports;
  final List<String> parts;
  final List<String> partOf;
  final String category;
  final String profile;
  final bool largeProfile;
  final List<String> keywords;

  const QuantumTestSourceMetadata({
    required this.path,
    required this.sha256,
    required this.lineCount,
    required this.imports,
    required this.exports,
    required this.parts,
    required this.partOf,
    required this.category,
    required this.profile,
    required this.largeProfile,
    required this.keywords,
  });

  factory QuantumTestSourceMetadata.fromJson(Map<String, dynamic> json) {
    return QuantumTestSourceMetadata(
      path: _string(json['path']),
      sha256: _string(json['sha256']),
      lineCount: _int(json['line_count'] ?? json['lineCount']),
      imports: _stringList(json['imports']),
      exports: _stringList(json['exports']),
      parts: _stringList(json['parts']),
      partOf: _stringList(json['part_of'] ?? json['partOf']),
      category: _string(json['category']),
      profile: _string(json['profile']),
      largeProfile: _bool(json['large_profile'] ?? json['largeProfile']),
      keywords: _stringList(json['keywords']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'path': path,
    'sha256': sha256,
    'lineCount': lineCount,
    'imports': imports,
    'exports': exports,
    'parts': parts,
    'partOf': partOf,
    'category': category,
    'profile': profile,
    'largeProfile': largeProfile,
    'keywords': keywords,
  };
}

@immutable
class QuantumTestRowSpec {
  final String id;
  final String purpose;
  final List<String> targetSymbols;
  final String setup;
  final String input;
  final String body;
  final String expected;
  final List<String> assertions;
  final List<String> metrics;
  final List<String> risks;
  final String cleanup;
  final List<String> tags;
  final String? notes;
  final String? skipReason;
  final Map<String, dynamic> raw;

  const QuantumTestRowSpec({
    required this.id,
    required this.purpose,
    required this.targetSymbols,
    required this.setup,
    required this.input,
    required this.body,
    required this.expected,
    required this.assertions,
    required this.metrics,
    required this.risks,
    required this.cleanup,
    required this.tags,
    required this.raw,
    this.notes,
    this.skipReason,
  });

  factory QuantumTestRowSpec.fromJson(Map<String, dynamic> json) {
    final targetSymbols =
        _stringList(json['target_symbols'] ?? json['targetSymbols']);
    final tags = _stringList(
      json['tags'] ??
          json['keywords'] ??
          json['target_symbols'] ??
          json['targetSymbols'],
    );
    return QuantumTestRowSpec(
      id: _string(json['id']),
      purpose: _string(json['purpose']),
      targetSymbols: targetSymbols,
      setup: _string(json['setup']),
      input: _string(json['input']),
      body: _string(json['body']),
      expected: _string(json['expected']),
      assertions: _stringList(json['assertions']),
      metrics: _stringList(json['metrics']),
      risks: _stringList(json['risks']),
      cleanup: _string(json['cleanup']),
      tags: tags.isNotEmpty
          ? tags
          : (targetSymbols.isNotEmpty ? targetSymbols : _stringList(json['surface'])),
      notes: _stringOrNull(json['notes']),
      skipReason: _stringOrNull(json['skip_reason'] ?? json['skipReason']),
      raw: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'purpose': purpose,
    'targetSymbols': targetSymbols,
    'setup': setup,
    'input': input,
    'body': body,
    'expected': expected,
    'assertions': assertions,
    'metrics': metrics,
    'risks': risks,
    'cleanup': cleanup,
    'tags': tags,
    if (notes != null) 'notes': notes,
    if (skipReason != null) 'skipReason': skipReason,
  };

  bool get isRunnable => skipReason == null && id.trim().isNotEmpty;
}

@immutable
class QuantumTestGroupSpec {
  final String name;
  final String description;
  final List<QuantumTestRowSpec> rows;
  final Map<String, dynamic> raw;

  const QuantumTestGroupSpec({
    required this.name,
    required this.description,
    required this.rows,
    required this.raw,
  });

  factory QuantumTestGroupSpec.fromJson(Map<String, dynamic> json) {
    final rows = <QuantumTestRowSpec>[];
    final rawRows = json['rows'];
    if (rawRows is List) {
      for (final item in rawRows) {
        if (item is Map) {
          rows.add(QuantumTestRowSpec.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return QuantumTestGroupSpec(
      name: _string(json['name']),
      description: _string(json['description']),
      rows: List<QuantumTestRowSpec>.unmodifiable(rows),
      raw: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'description': description,
    'rows': rows.map((e) => e.toJson()).toList(growable: false),
  };
}

@immutable
class QuantumTestSupplementSpec {
  final String path;
  final String name;
  final String description;
  final List<String> groups;
  final Map<String, dynamic> raw;

  const QuantumTestSupplementSpec({
    required this.path,
    required this.name,
    required this.description,
    required this.groups,
    required this.raw,
  });

  factory QuantumTestSupplementSpec.fromJson(Map<String, dynamic> json) {
    return QuantumTestSupplementSpec(
      path: _string(json['path']),
      name: _string(json['name']),
      description: _string(json['description']),
      groups: _stringList(json['groups']),
      raw: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'path': path,
    'name': name,
    'description': description,
    'groups': groups,
  };
}

@immutable
class QuantumTestManifest {
  final String schemaVersion;
  final String docKind;
  final String file;
  final String layer;
  final String profile;
  final String testDocStatus;
  final String lastReviewed;
  final QuantumTestSourceMetadata sourceMetadata;
  final Map<String, dynamic> surfaceSummary;
  final String focus;
  final List<String> coverageTargets;
  final Map<String, dynamic> testDimensions;
  final Map<String, dynamic> reusablePresets;
  final List<QuantumTestGroupSpec> groups;
  final List<String> regenerationTriggers;
  final List<QuantumTestSupplementSpec> supplements;
  final List<String> notes;
  final List<String> profiles;
  final String manifestPath;

  const QuantumTestManifest({
    required this.schemaVersion,
    required this.docKind,
    required this.file,
    required this.layer,
    required this.profile,
    required this.testDocStatus,
    required this.lastReviewed,
    required this.sourceMetadata,
    required this.surfaceSummary,
    required this.focus,
    required this.coverageTargets,
    required this.testDimensions,
    required this.reusablePresets,
    required this.groups,
    required this.regenerationTriggers,
    required this.supplements,
    required this.notes,
    required this.profiles,
    required this.manifestPath,
  });

  factory QuantumTestManifest.fromJson(
    Map<String, dynamic> json, {
    required String manifestPath,
  }) {
    final groups = <QuantumTestGroupSpec>[];
    final rawGroups = json['groups'];
    if (rawGroups is List) {
      for (final item in rawGroups) {
        if (item is Map) {
          groups.add(QuantumTestGroupSpec.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final supplements = <QuantumTestSupplementSpec>[];
    final rawSupplements = json['supplements'];
    if (rawSupplements is List) {
      for (final item in rawSupplements) {
        if (item is Map) {
          supplements.add(QuantumTestSupplementSpec.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final metaJson = json['source_metadata'] is Map
        ? Map<String, dynamic>.from(json['source_metadata'] as Map)
        : json['sourceMetadata'] is Map
            ? Map<String, dynamic>.from(json['sourceMetadata'] as Map)
            : <String, dynamic>{};

    return QuantumTestManifest(
      schemaVersion: _string(json['schema_version'] ?? json['schemaVersion']),
      docKind: _string(json['doc_kind'] ?? json['docKind']),
      file: _string(json['file']),
      layer: _string(json['layer']),
      profile: _string(json['profile']),
      testDocStatus: _string(json['test_doc_status'] ?? json['testDocStatus']),
      lastReviewed: _string(json['last_reviewed'] ?? json['lastReviewed']),
      sourceMetadata: QuantumTestSourceMetadata.fromJson(metaJson),
      surfaceSummary: json['surface_summary'] is Map
          ? Map<String, dynamic>.from(json['surface_summary'] as Map)
          : json['surfaceSummary'] is Map
              ? Map<String, dynamic>.from(json['surfaceSummary'] as Map)
              : <String, dynamic>{},
      focus: _string(json['focus']),
      coverageTargets: _stringList(json['coverage_targets'] ?? json['coverageTargets']),
      testDimensions: json['test_dimensions'] is Map
          ? Map<String, dynamic>.from(json['test_dimensions'] as Map)
          : json['testDimensions'] is Map
              ? Map<String, dynamic>.from(json['testDimensions'] as Map)
              : <String, dynamic>{},
      reusablePresets: json['reusable_presets'] is Map
          ? Map<String, dynamic>.from(json['reusable_presets'] as Map)
          : json['reusablePresets'] is Map
              ? Map<String, dynamic>.from(json['reusablePresets'] as Map)
              : <String, dynamic>{},
      groups: List<QuantumTestGroupSpec>.unmodifiable(groups),
      regenerationTriggers: _stringList(json['regeneration_triggers'] ?? json['regenerationTriggers']),
      supplements: List<QuantumTestSupplementSpec>.unmodifiable(supplements),
      notes: _stringList(json['notes']),
      profiles: _stringList(json['profiles']),
      manifestPath: manifestPath,
    );
  }

  int get groupCount => groups.length;
  int get rowCount => groups.fold<int>(0, (sum, group) => sum + group.rows.length);
  int get supplementCount => supplements.length;

  String get sourcePath => sourceMetadata.path;

  List<String> surfaceNames() {
    final raw = surfaceSummary['classes_enums_typedefs_mixins_extensions_functions'];
    if (raw is List) return raw.map((e) => e.toString()).toList(growable: false);
    return const <String>[];
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'schemaVersion': schemaVersion,
    'docKind': docKind,
    'file': file,
    'layer': layer,
    'profile': profile,
    'testDocStatus': testDocStatus,
    'lastReviewed': lastReviewed,
    'sourceMetadata': sourceMetadata.toJson(),
    'surfaceSummary': Map<String, dynamic>.from(surfaceSummary),
    'focus': focus,
    'coverageTargets': coverageTargets,
    'testDimensions': Map<String, dynamic>.from(testDimensions),
    'reusablePresets': Map<String, dynamic>.from(reusablePresets),
    'groups': groups.map((e) => e.toJson()).toList(growable: false),
    'regenerationTriggers': regenerationTriggers,
    'supplements': supplements.map((e) => e.toJson()).toList(growable: false),
    'notes': notes,
    'profiles': profiles,
    'manifestPath': manifestPath,
  };

  List<QuantumTestIssue> validate({
    String? sourceText,
    bool strict = true,
  }) {
    final issues = <QuantumTestIssue>[];
    if (schemaVersion.trim().isEmpty) {
      issues.add(const QuantumTestIssue.error('manifest.schemaVersion', 'Missing schema version.'));
    }
    if (docKind.trim().isEmpty) {
      issues.add(const QuantumTestIssue.error('manifest.docKind', 'Missing doc kind.'));
    }
    if (file.trim().isEmpty) {
      issues.add(const QuantumTestIssue.error('manifest.file', 'Missing file name.'));
    }
    if (sourceMetadata.path.trim().isEmpty) {
      issues.add(const QuantumTestIssue.error('source.path', 'Missing source path.'));
    }
    if (groupCount == 0) {
      issues.add(const QuantumTestIssue.error('groups.empty', 'No groups were declared.'));
    }
    final groupNames = <String>{};
    final rowIds = <String>{};
    for (var gi = 0; gi < groups.length; gi++) {
      final group = groups[gi];
      if (group.name.trim().isEmpty) {
        issues.add(QuantumTestIssue.error('group[$gi].name', 'Group name is empty.'));
      } else if (!groupNames.add(group.name)) {
        issues.add(QuantumTestIssue.error('group[$gi].name', 'Duplicate group name: ${group.name}'));
      }
      if (group.rows.isEmpty) {
        issues.add(QuantumTestIssue.error('group[$gi].rows', 'Group ${group.name} has no rows.'));
      }
      for (var ri = 0; ri < group.rows.length; ri++) {
        final row = group.rows[ri];
        final rowPath = 'groups[$gi].rows[$ri]';
        if (row.id.trim().isEmpty) {
          issues.add(QuantumTestIssue.error('$rowPath.id', 'Row id is empty.'));
        } else if (!rowIds.add(row.id)) {
          issues.add(QuantumTestIssue.error('$rowPath.id', 'Duplicate row id: ${row.id}'));
        }
        if (row.purpose.trim().isEmpty) {
          issues.add(QuantumTestIssue.warn('$rowPath.purpose', 'Row purpose is empty.'));
        }
        if (row.targetSymbols.isEmpty) {
          issues.add(QuantumTestIssue.warn('$rowPath.targetSymbols', 'Row target symbols are empty.'));
        }
        if (row.expected.trim().isEmpty) {
          issues.add(QuantumTestIssue.warn('$rowPath.expected', 'Row expected is empty.'));
        }
        if (row.assertions.isEmpty && strict) {
          issues.add(QuantumTestIssue.warn('$rowPath.assertions', 'Row has no assertions.'));
        }
        if (row.metrics.isEmpty && strict) {
          issues.add(QuantumTestIssue.warn('$rowPath.metrics', 'Row has no metrics.'));
        }
      }
    }

    if (sourceText != null && sourceText.isNotEmpty) {
      for (final needle in sourceMetadata.imports) {
        if (needle.trim().isEmpty) continue;
        if (!sourceText.contains(needle)) {
          issues.add(QuantumTestIssue.warn('source.imports', 'Import not found in source text: $needle'));
        }
      }
      for (final symbol in surfaceNames()) {
        if (symbol.trim().isEmpty) continue;
        if (!sourceText.contains(symbol)) {
          issues.add(QuantumTestIssue.warn('source.surface', 'Declared symbol not found in source text: $symbol'));
        }
      }
    }

    return issues;
  }
}

@immutable
class QuantumTestCaseSpec {
  final String manifestPath;
  final QuantumTestManifest manifest;
  final QuantumTestGroupSpec group;
  final QuantumTestRowSpec row;
  final int groupIndex;
  final int rowIndex;
  final String uniqueId;

  const QuantumTestCaseSpec({
    required this.manifestPath,
    required this.manifest,
    required this.group,
    required this.row,
    required this.groupIndex,
    required this.rowIndex,
    required this.uniqueId,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'manifestPath': manifestPath,
    'manifestFile': manifest.file,
    'sourcePath': manifest.sourcePath,
    'group': group.name,
    'row': row.id,
    'uniqueId': uniqueId,
    'purpose': row.purpose,
    'input': row.input,
    'expected': row.expected,
    'targetSymbols': row.targetSymbols,
    'assertions': row.assertions,
    'metrics': row.metrics,
    'risks': row.risks,
    'tags': row.tags,
  };
}

@immutable
class QuantumTestIssue {
  final QuantumTestStatus status;
  final String path;
  final String message;

  const QuantumTestIssue({
    required this.status,
    required this.path,
    required this.message,
  });

  const QuantumTestIssue.error(String path, String message)
      : status = QuantumTestStatus.error,
        path = path,
        message = message;

  const QuantumTestIssue.warn(String path, String message)
      : status = QuantumTestStatus.warn,
        path = path,
        message = message;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'status': status.name,
    'path': path,
    'message': message,
  };
}

@immutable
class QuantumTestResult {
  final String uniqueId;
  final String manifestPath;
  final String filePath;
  final String group;
  final String row;
  final QuantumTestStatus status;
  final QuantumTestPhase phase;
  final String summary;
  final String expected;
  final String actual;
  final String? error;
  final String? stackTrace;
  final Duration duration;
  final Map<String, dynamic> details;

  const QuantumTestResult({
    required this.uniqueId,
    required this.manifestPath,
    required this.filePath,
    required this.group,
    required this.row,
    required this.status,
    required this.phase,
    required this.summary,
    required this.expected,
    required this.actual,
    required this.duration,
    required this.details,
    this.error,
    this.stackTrace,
  });

  bool get ok => status == QuantumTestStatus.pass;

  Map<String, dynamic> toJson({bool compact = true}) => <String, dynamic>{
    'uniqueId': uniqueId,
    'manifestPath': manifestPath,
    'filePath': filePath,
    'group': group,
    'row': row,
    'status': status.name,
    'phase': phase.name,
    'summary': summary,
    'expected': compact ? _compactValue(expected) : expected,
    'actual': compact ? _compactValue(actual) : actual,
    if (error != null) 'error': _compactValue(error!),
    if (stackTrace != null && !compact) 'stackTrace': stackTrace,
    'durationMs': duration.inMilliseconds,
    'details': compact ? _compactMap(details) : Map<String, dynamic>.from(details),
  };
}

@immutable
class QuantumTestReport {
  final String rootPath;
  final DateTime startedAt;
  final DateTime finishedAt;
  final List<QuantumTestResult> results;
  final List<QuantumTestIssue> issues;

  const QuantumTestReport({
    required this.rootPath,
    required this.startedAt,
    required this.finishedAt,
    required this.results,
    required this.issues,
  });

  int get total => results.length;
  int get passed => results.where((r) => r.ok).length;
  int get failed => results.where((r) => !r.ok).length;
  Duration get duration => finishedAt.difference(startedAt);

  Map<String, dynamic> toJson({bool compact = true}) => <String, dynamic>{
    'rootPath': rootPath,
    'startedAt': startedAt.toIso8601String(),
    'finishedAt': finishedAt.toIso8601String(),
    'durationMs': duration.inMilliseconds,
    'total': total,
    'passed': passed,
    'failed': failed,
    'issues': issues.map((e) => e.toJson()).toList(growable: false),
    'results': results.map((e) => e.toJson(compact: compact)).toList(growable: false),
  };

  String toPrettyJson({bool compact = true}) => const JsonEncoder.withIndent('  ').convert(toJson(compact: compact));

  String summaryLine() => 'total=$total passed=$passed failed=$failed duration=${duration.inMilliseconds}ms';
}

@immutable
class QuantumTestContext {
  final QuantumTestManifest manifest;
  final QuantumTestCaseSpec spec;
  final Map<String, dynamic> env;

  const QuantumTestContext({
    required this.manifest,
    required this.spec,
    required this.env,
  });
}

typedef QuantumTestExecutor = Future<QuantumTestResult> Function(
  QuantumTestCaseSpec spec,
  QuantumTestContext context,
);

String _string(dynamic value) => value == null ? '' : value.toString();
String? _stringOrNull(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _bool(dynamic value) {
  if (value is bool) return value;
  final text = value?.toString().trim().toLowerCase();
  return text == 'true' || text == '1' || text == 'yes' || text == 'on';
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return List<String>.unmodifiable(value.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty));
  }
  if (value == null) return const <String>[];
  final text = value.toString().trim();
  if (text.isEmpty) return const <String>[];
  return List<String>.unmodifiable(<String>[text]);
}

dynamic _compactValue(dynamic value) {
  if (value == null) return null;
  if (value is String) return value.length > 240 ? '${value.substring(0, 240)}…' : value;
  if (value is Map) return _compactMap(Map<String, dynamic>.from(value));
  if (value is Iterable) {
    final items = value.map(_compactValue).take(20).toList(growable: false);
    return items.length < value.length
        ? <String, dynamic>{'items': items, 'truncated': true, 'count': value.length}
        : items;
  }
  return value;
}

Map<String, dynamic> _compactMap(Map<String, dynamic> input) {
  final out = <String, dynamic>{};
  for (final entry in input.entries) {
    if (out.length >= 24) {
      out['_truncated'] = true;
      break;
    }
    final value = entry.value;
    if (value is String && value.length > 240) {
      out[entry.key] = '${value.substring(0, 240)}…';
    } else {
      out[entry.key] = _compactValue(value);
    }
  }
  return out;
}
