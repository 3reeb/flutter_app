
// ════════════════════════════════════════════════════════════════════════════
// QUANTUM SDUI TEST ENGINE — shared model + report types
// quantum_sdui_test_engine_shared.dart
//
// This file contains the portable data model used by the IO/web facades.
// The runtime implementation adds file scanning and render smoke testing.
// ════════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@immutable
class QuantumSduiTestViewport {
  final double width;
  final double height;
  final double pixelRatio;

  const QuantumSduiTestViewport({
    required this.width,
    required this.height,
    this.pixelRatio = 1.0,
  });

  Size get logicalSize => Size(width, height);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'width': width,
        'height': height,
        'pixelRatio': pixelRatio,
      };

  factory QuantumSduiTestViewport.fromJson(dynamic value) {
    if (value is Map) {
      return QuantumSduiTestViewport(
        width: _toDouble(value['width'], fallback: 390),
        height: _toDouble(value['height'], fallback: 844),
        pixelRatio: _toDouble(value['pixelRatio'], fallback: 1.0),
      );
    }
    if (value is List && value.length >= 2) {
      return QuantumSduiTestViewport(
        width: _toDouble(value[0], fallback: 390),
        height: _toDouble(value[1], fallback: 844),
        pixelRatio: value.length >= 3 ? _toDouble(value[2], fallback: 1.0) : 1.0,
      );
    }
    return const QuantumSduiTestViewport(width: 390, height: 844, pixelRatio: 1.0);
  }
}

@immutable
class QuantumSduiTestMeta {
  final String id;
  final String title;
  final String? description;
  final List<String> tags;
  final QuantumSduiTestViewport viewport;
  final Color background;
  final bool allowSolidFill;
  final bool allowBlank;
  final int timeoutMs;
  final Map<String, dynamic> env;

  const QuantumSduiTestMeta({
    required this.id,
    required this.title,
    this.description,
    this.tags = const <String>[],
    this.viewport = const QuantumSduiTestViewport(width: 390, height: 844),
    this.background = const Color(0xFF0B1020),
    this.allowSolidFill = false,
    this.allowBlank = false,
    this.timeoutMs = 8000,
    this.env = const <String, dynamic>{},
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        if (description != null) 'description': description,
        'tags': tags,
        'viewport': viewport.toJson(),
        'background': _colorToHex(background),
        'allowSolidFill': allowSolidFill,
        'allowBlank': allowBlank,
        'timeoutMs': timeoutMs,
        if (env.isNotEmpty) 'env': env,
      };

  factory QuantumSduiTestMeta.fromJson(
    String fallbackId,
    Map<String, dynamic> json,
  ) {
    final dynamic rawViewport = json['viewport'] ?? json['__viewport'];
    final dynamic rawTags = json['tags'] ?? json['__tags'];
    final Map<String, dynamic> env = json['env'] is Map
        ? Map<String, dynamic>.from(json['env'] as Map)
        : const <String, dynamic>{};

    return QuantumSduiTestMeta(
      id: json['id']?.toString().trim().isNotEmpty == true
          ? json['id'].toString()
          : fallbackId,
      title: json['title']?.toString().trim().isNotEmpty == true
          ? json['title'].toString()
          : (json['name']?.toString().trim().isNotEmpty == true
              ? json['name'].toString()
              : fallbackId),
      description: json['description']?.toString(),
      tags: _toStringList(rawTags),
      viewport: QuantumSduiTestViewport.fromJson(rawViewport),
      background: _parseColor(json['background']?.toString() ??
          json['canvas']?.toString() ??
          '#0B1020'),
      allowSolidFill: _toBool(json['allowSolidFill']) ||
          _toBool(json['solidFillAllowed']),
      allowBlank: _toBool(json['allowBlank']) || _toBool(json['blankAllowed']),
      timeoutMs: _toInt(json['timeoutMs'], fallback: 8000),
      env: env,
    );
  }
}

@immutable
class QuantumSduiTestCase {
  final String filePath;
  final String source;
  final Map<String, dynamic> root;
  final QuantumSduiTestMeta meta;
  final int sourceHash;

  const QuantumSduiTestCase({
    required this.filePath,
    required this.source,
    required this.root,
    required this.meta,
    required this.sourceHash,
  });

  String get id => meta.id;
  String get title => meta.title;
  String get description => meta.description ?? '';
  QuantumSduiTestViewport get viewport => meta.viewport;
  Map<String, dynamic> get env => meta.env;
  bool get allowBlank => meta.allowBlank;
  bool get allowSolidFill => meta.allowSolidFill;
  int get timeoutMs => meta.timeoutMs;
  Color get background => meta.background;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'filePath': filePath,
        'sourceHash': sourceHash,
        'meta': meta.toJson(),
        'root': root,
      };

  /// Returns the actual SDUI root to compile, with test-only metadata removed.
  Map<String, dynamic> compileRoot() {
    final copy = Map<String, dynamic>.from(root);
    for (final key in const <String>[
      '__meta',
      '_meta',
      '__viewport',
      '__env',
      '__tags',
      '__expect',
      '__assert',
      '__test',
      '__name',
    ]) {
      copy.remove(key);
    }

    // Some authors prefer wrapping UI in `ui`, `root`, or `view`.
    final dynamic explicit = copy['root'] ?? copy['ui'] ?? copy['view'];
    if (explicit is Map) {
      return Map<String, dynamic>.from(explicit);
    }
    if (explicit is String) {
      try {
        final dynamic decoded = jsonDecode(explicit);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }

    return copy;
  }

  factory QuantumSduiTestCase.fromFilePath(
    String filePath,
    String source,
    Map<String, dynamic> root,
  ) {
    final fallbackId = _slugFromPath(filePath);
    final Map<String, dynamic> metaJson = <String, dynamic>{
      if (root['__meta'] is Map) ...Map<String, dynamic>.from(root['__meta'] as Map),
      if (root['_meta'] is Map) ...Map<String, dynamic>.from(root['_meta'] as Map),
      if (root['__viewport'] != null) 'viewport': root['__viewport'],
      if (root['__env'] is Map) 'env': root['__env'],
      if (root['__tags'] != null) 'tags': root['__tags'],
      if (root['__expect'] is Map) ...Map<String, dynamic>.from(root['__expect'] as Map),
      if (root['__assert'] is Map) ...Map<String, dynamic>.from(root['__assert'] as Map),
      if (root['__test'] is Map) ...Map<String, dynamic>.from(root['__test'] as Map),
      if (root['__name'] != null) 'title': root['__name'],
    };

    final meta = QuantumSduiTestMeta.fromJson(
      fallbackId,
      <String, dynamic>{
        'id': metaJson['id'] ?? fallbackId,
        'title': metaJson['title'] ?? root['title'] ?? root['name'] ?? fallbackId,
        'description': metaJson['description'] ?? root['description'],
        'tags': metaJson['tags'] ?? root['tags'],
        'viewport': metaJson['viewport'] ?? root['viewport'],
        'background': metaJson['background'] ?? root['background'],
        'allowSolidFill': metaJson['allowSolidFill'] ?? root['allowSolidFill'],
        'allowBlank': metaJson['allowBlank'] ?? root['allowBlank'],
        'timeoutMs': metaJson['timeoutMs'] ?? root['timeoutMs'],
        'env': metaJson['env'] ?? root['env'],
      },
    );

    return QuantumSduiTestCase(
      filePath: filePath,
      source: source,
      root: root,
      meta: meta,
      sourceHash: source.hashCode,
    );
  }
}

@immutable
class QuantumSduiRenderAnalysis {
  final bool blank;
  final bool uniform;
  final int distinctBuckets;
  final double luminanceStdDev;
  final double backgroundMatchRatio;
  final int totalPixels;
  final int visiblePixels;
  final int width;
  final int height;
  final String? note;

  const QuantumSduiRenderAnalysis({
    required this.blank,
    required this.uniform,
    required this.distinctBuckets,
    required this.luminanceStdDev,
    required this.backgroundMatchRatio,
    required this.totalPixels,
    required this.visiblePixels,
    required this.width,
    required this.height,
    this.note,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'blank': blank,
        'uniform': uniform,
        'distinctBuckets': distinctBuckets,
        'luminanceStdDev': luminanceStdDev,
        'backgroundMatchRatio': backgroundMatchRatio,
        'totalPixels': totalPixels,
        'visiblePixels': visiblePixels,
        'width': width,
        'height': height,
        if (note != null) 'note': note,
      };
}

enum QuantumSduiTestPhase { discovered, compiled, rendered, failed, skipped }

@immutable
class QuantumSduiTestResult {
  final String caseId;
  final String title;
  final String filePath;
  final QuantumSduiTestPhase phase;
  final bool ok;
  final bool compileOk;
  final bool renderOk;
  final bool blankRender;
  final Duration duration;
  final String? message;
  final String? error;
  final String? stackTrace;
  final QuantumSduiRenderAnalysis? analysis;
  final Map<String, dynamic> details;

  const QuantumSduiTestResult({
    required this.caseId,
    required this.title,
    required this.filePath,
    required this.phase,
    required this.ok,
    required this.compileOk,
    required this.renderOk,
    required this.blankRender,
    required this.duration,
    this.message,
    this.error,
    this.stackTrace,
    this.analysis,
    this.details = const <String, dynamic>{},
  });

  factory QuantumSduiTestResult.pass({
    required String caseId,
    required String title,
    required String filePath,
    required Duration duration,
    required QuantumSduiRenderAnalysis analysis,
    String? message,
    Map<String, dynamic> details = const <String, dynamic>{},
  }) {
    return QuantumSduiTestResult(
      caseId: caseId,
      title: title,
      filePath: filePath,
      phase: QuantumSduiTestPhase.rendered,
      ok: true,
      compileOk: true,
      renderOk: true,
      blankRender: analysis.blank,
      duration: duration,
      message: message ?? 'Passed',
      analysis: analysis,
      details: details,
    );
  }

  factory QuantumSduiTestResult.fail({
    required String caseId,
    required String title,
    required String filePath,
    required Duration duration,
    required QuantumSduiTestPhase phase,
    required String message,
    String? error,
    String? stackTrace,
    QuantumSduiRenderAnalysis? analysis,
    Map<String, dynamic> details = const <String, dynamic>{},
  }) {
    return QuantumSduiTestResult(
      caseId: caseId,
      title: title,
      filePath: filePath,
      phase: phase,
      ok: false,
      compileOk: phase == QuantumSduiTestPhase.compiled ||
          phase == QuantumSduiTestPhase.rendered,
      renderOk: phase == QuantumSduiTestPhase.rendered,
      blankRender: analysis?.blank ?? false,
      duration: duration,
      message: message,
      error: error,
      stackTrace: stackTrace,
      analysis: analysis,
      details: details,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'caseId': caseId,
        'title': title,
        'filePath': filePath,
        'phase': phase.name,
        'ok': ok,
        'compileOk': compileOk,
        'renderOk': renderOk,
        'blankRender': blankRender,
        'durationMs': duration.inMilliseconds,
        if (message != null) 'message': message,
        if (error != null) 'error': error,
        if (stackTrace != null) 'stackTrace': stackTrace,
        if (analysis != null) 'analysis': analysis!.toJson(),
        if (details.isNotEmpty) 'details': details,
      };
}

@immutable
class QuantumSduiTestReport {
  final List<QuantumSduiTestResult> results;
  final DateTime startedAt;
  final DateTime finishedAt;
  final String folderPath;
  final bool recursive;

  const QuantumSduiTestReport({
    required this.results,
    required this.startedAt,
    required this.finishedAt,
    required this.folderPath,
    required this.recursive,
  });

  int get total => results.length;
  int get passed => results.where((r) => r.ok).length;
  int get failed => results.where((r) => !r.ok).length;
  int get blankFailures => results.where((r) => r.blankRender && !r.ok).length;
  int get compileFailures => results.where((r) => !r.compileOk).length;
  int get renderFailures => results.where((r) => r.compileOk && !r.renderOk).length;
  Duration get duration => finishedAt.difference(startedAt);

  bool get healthy =>
      failed == 0 && compileFailures == 0 && renderFailures == 0 && blankFailures == 0;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'folderPath': folderPath,
        'recursive': recursive,
        'startedAt': startedAt.toIso8601String(),
        'finishedAt': finishedAt.toIso8601String(),
        'durationMs': duration.inMilliseconds,
        'total': total,
        'passed': passed,
        'failed': failed,
        'blankFailures': blankFailures,
        'compileFailures': compileFailures,
        'renderFailures': renderFailures,
        'healthy': healthy,
        'results': results.map((e) => e.toJson()).toList(growable: false),
      };

  String toPrettyJson() =>
      const JsonEncoder.withIndent('  ').convert(toJson());
}

@immutable
class QuantumSduiTestException implements Exception {
  final String message;
  final String? code;
  final Object? cause;
  const QuantumSduiTestException(this.message, {this.code, this.cause});

  @override
  String toString() => code == null ? message : '[$code] $message';
}

double _toDouble(dynamic value, {required double fallback}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

int _toInt(dynamic value, {required int fallback}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  final s = value?.toString().trim().toLowerCase() ?? '';
  return s == 'true' || s == '1' || s == 'yes' || s == 'on';
}

List<String> _toStringList(dynamic value) {
  if (value is List) {
    return value.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList(growable: false);
  }
  if (value is String && value.trim().isNotEmpty) {
    return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(growable: false);
  }
  return const <String>[];
}

String _slugFromPath(String filePath) {
  final normalized = filePath.replaceAll('\\', '/');
  final fileName = normalized.split('/').last.replaceAll(RegExp(r'\.json$'), '');
  final slug = fileName
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  return slug.isEmpty ? 'case-${filePath.hashCode.abs()}' : slug;
}

Color _parseColor(String value) {
  final s = value.trim();
  if (s.isEmpty) return const Color(0xFF0B1020);
  if (s.startsWith('#')) {
    final hex = s.substring(1);
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }
  }
  switch (s.toLowerCase()) {
    case 'white':
      return Colors.white;
    case 'black':
      return Colors.black;
    case 'transparent':
      return Colors.transparent;
  }
  return const Color(0xFF0B1020);
}

String _colorToHex(Color c) =>
    '#${c.alpha.toRadixString(16).padLeft(2, '0')}${c.red.toRadixString(16).padLeft(2, '0')}${c.green.toRadixString(16).padLeft(2, '0')}${c.blue.toRadixString(16).padLeft(2, '0')}';

double _luma(int r, int g, int b) => (0.2126 * r) + (0.7152 * g) + (0.0722 * b);

double _stdDevFromBuckets(Map<int, int> buckets, int total) {
  if (total <= 0) return 0;
  double sum = 0;
  double sumSq = 0;
  buckets.forEach((_, count) {
    sum += count;
    sumSq += count * count;
  });
  final mean = sum / buckets.length;
  final variance = math.max(0, (sumSq / buckets.length) - (mean * mean));
  return math.sqrt(variance);
}
