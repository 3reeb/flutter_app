// ════════════════════════════════════════════════════════════════════════════
// QUANTUM YAML ENGINE v1.1 — OMEGA YAML-FIRST CONFIG SYSTEM
// quantum_yaml_engine.dart
//
// FEATURES:
// 1. Zero-boilerplate: entire app from a single APP.yaml
// 2. $import: directive — compose any YAML/JSON from any other
// 3. Circular-import detection with clear error messages
// 4. Content-hash deduplication — never parse the same bytes twice
// 5. Parallel Isolate resolution for deep import trees
// 6. Environment interpolation: {{env.MY_VAR}}
// 7. Type-safe config extraction with fallbacks
// 8. LRU + TTL cache (plugs into existing QLRuntimeCache)
// 9. Supports .yaml, .yml, and .json extensions uniformly
// 10. Thread-safe singleton with lazy initialization
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:flutter/foundation.dart';
import '../foundation/quantum_isolate_bridge.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import '../../quantum.dart';
// ─────────────────────────────────────────────────────────────────────── §1 ─
//  EXCEPTIONS
// ────────────────────────────────────────────────────────────────────────────

class QuantumYamlException implements Exception {
  final String message;
  final String? sourcePath;
  final String? importChain;
  const QuantumYamlException(this.message, {this.sourcePath, this.importChain});

  @override
  String toString() {
    final parts = <String>['QuantumYamlException: $message'];
    if (sourcePath != null) parts.add('  Source: $sourcePath');
    if (importChain != null) parts.add('  Import chain: $importChain');
    return parts.join('\n');
  }
}

// ─────────────────────────────────────────────────────────────────────── §2 ─
//  PARSED YAML NODE — IMMUTABLE RESULT TREE
// ────────────────────────────────────────────────────────────────────────────

/// Immutable, fully-resolved YAML/JSON node.
/// Every `$import:` directive has been replaced by the imported content.
/// Every `{{env.X}}` has been substituted.
@immutable
class QLYamlNode {
  final dynamic _raw;
  const QLYamlNode._(this._raw);

  static const QLYamlNode empty = QLYamlNode._(null);

  factory QLYamlNode.fromRaw(dynamic raw) => QLYamlNode._(raw);

  bool get isNull => _raw == null;
  bool get isMap => _raw is Map;
  bool get isList => _raw is List;
  bool get isString => _raw is String;
  bool get isNumber => _raw is num;
  bool get isBool => _raw is bool;

  /// Access as raw dynamic value.
  dynamic get raw => _raw;

  /// Access as Map<String, dynamic> or empty map.
  Map<String, dynamic> get asMap {
    if (_raw is Map) return Map<String, dynamic>.from(_raw as Map);
    return const <String, dynamic>{};
  }

  /// Access as List<dynamic> or empty list.
  List<dynamic> get asList {
    if (_raw is List) return List<dynamic>.from(_raw as List);
    if (_raw != null) return [_raw];
    return const <dynamic>[];
  }

  String get asString => _raw?.toString() ?? '';
  double get asDouble =>
      _raw is num ? (_raw as num).toDouble() : double.tryParse(asString) ?? 0.0;
  int get asInt =>
      _raw is num ? (_raw as num).toInt() : int.tryParse(asString) ?? 0;
  bool get asBool {
    if (_raw is bool) return _raw as bool;
    final s = asString.toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
  }

  /// Navigate into nested keys.  Returns [QLYamlNode.empty] on missing.
  QLYamlNode operator [](String key) {
    if (_raw is Map) {
      final v = (_raw as Map)[key];
      return v != null ? QLYamlNode._(v) : QLYamlNode.empty;
    }
    return QLYamlNode.empty;
  }

  QLYamlNode path(List<String> segments) {
    QLYamlNode current = this;
    for (final seg in segments) {
      current = current[seg];
      if (current.isNull) return QLYamlNode.empty;
    }
    return current;
  }

  /// Returns a list of child [QLYamlNode] objects.
  List<QLYamlNode> get children =>
      asList.map(QLYamlNode.fromRaw).toList(growable: false);

  @override
  String toString() => _raw.toString();
}

// ─────────────────────────────────────────────────────────────────────── §3 ─
//  IMPORT RECORD — tracks what is being imported for cycle detection
// ────────────────────────────────────────────────────────────────────────────

class _ImportFrame {
  final String path;
  final _ImportFrame? parent;

  const _ImportFrame(this.path, [this.parent]);

  /// Detect if [candidate] is already in the import chain.
  bool contains(String candidate) {
    _ImportFrame? f = this;
    while (f != null) {
      if (f.path == candidate) return true;
      f = f.parent;
    }
    return false;
  }

  String get chain {
    final parts = <String>[];
    _ImportFrame? f = this;
    while (f != null) {
      parts.add(f.path);
      f = f.parent;
    }
    return parts.reversed.join(' → ');
  }
}

// ─────────────────────────────────────────────────────────────────────── §4 ─
//  ENVIRONMENT REGISTRY
// ────────────────────────────────────────────────────────────────────────────

/// Global environment variable registry for `{{env.VAR}}` interpolation.
class QLYamlEnv {
  static final Map<String, String> _vars = {};

  /// Seed from a Map (typically loaded from ENV.yaml or platform env).
  static void seed(Map<String, String> vars) => _vars.addAll(vars);

  /// Override a single variable at runtime.
  static void set(String key, String value) => _vars[key] = value;

  /// Retrieve a variable. Returns empty string if missing.
  static String get(String key) => _vars[key] ?? '';

  /// Check whether a key is defined.
  static bool has(String key) => _vars.containsKey(key);

  static Map<String, String> get snapshot => Map.unmodifiable(_vars);
}

// ─────────────────────────────────────────────────────────────────────── §5 ─
//  QUANTUM YAML ENGINE — SINGLETON
// ────────────────────────────────────────────────────────────────────────────

/// The Quantum YAML Engine.
///
/// All public methods are safe to call from the main isolate.
/// Heavy parsing is offloaded to background isolates automatically
/// for files > 8 KB.
class QuantumYamlEngine {
  // ── Singleton ──────────────────────────────────────────────────────────────
  static final QuantumYamlEngine instance = QuantumYamlEngine._();
  QuantumYamlEngine._();

  /// Resolves the absolute path to the flutter project root in debug mode.
  static String? getProjectRoot() {
    if (!kDebugMode || kIsWeb) return null;
    Directory current = Directory(Platform.resolvedExecutable).parent;
    while (current.path != current.parent.path) {
      if (File('${current.path}/pubspec.yaml').existsSync()) {
        return current.path;
      }
      current = current.parent;
    }
    // Fallback
    if (File('${Directory.current.path}/pubspec.yaml').existsSync()) {
      return Directory.current.path;
    }
    return null;
  }

  // ── Content-Hash Cache: raw bytes → resolved Map ──────────────────────────
  // Key: stable hash of (assetPath + raw content bytes)
  final QLRuntimeCache<Map<String, dynamic>> _resolvedCache =
      QLRuntimeCache<Map<String, dynamic>>(
          config: const QLRuntimeCacheConfig(
              maxEntries: 512,
              maxWeight: 24 * 1024 * 1024, // 24 MB
              defaultTtl: null));

  // ── Raw-string cache: path → raw string (avoids double-loading assets) ────
  final QLRuntimeCache<String> _rawStringCache = QLRuntimeCache<String>(
      config: const QLRuntimeCacheConfig(
          maxEntries: 256, maxWeight: 8 * 1024 * 1024));

  // ── In-flight futures: prevent duplicate concurrent loads ─────────────────
  final Map<String, Future<Map<String, dynamic>>> _inFlight = {};

  // ── Warm the engine: preload essential config files ───────────────────────
  bool _warmed = false;

  /// Load and fully resolve a YAML/JSON asset file.
  ///
  /// - Parses YAML or JSON based on file extension.
  /// - Resolves all `$import:` directives recursively.
  /// - Substitutes `{{env.VAR}}` and `{{env.VAR | default: fallback}}`.
  /// - Caches the result by content hash — identical files cost O(1).
  ///
  /// Safe to call multiple times; subsequent calls are cache hits.
  Future<Map<String, dynamic>> load(
    String assetPath, {
    bool useCache = true,
    Map<String, String>? extraEnv,
  }) async {
    // Normalise path
    final String normalPath = _normalise(assetPath);

    // Deduplicate concurrent loads
    if (_inFlight.containsKey(normalPath)) {
      return _inFlight[normalPath]!;
    }

    final completer = Completer<Map<String, dynamic>>();
    _inFlight[normalPath] = completer.future;

    try {
      final result = await _loadInternal(
        normalPath,
        frame: _ImportFrame(normalPath),
        useCache: useCache,
        extraEnv: extraEnv,
      );
      completer.complete(result);
    } catch (e, st) {
      completer.completeError(e, st);
    } finally {
      _inFlight.remove(normalPath);
    }

    return completer.future;
  }

  /// Load a QLYamlNode (typed wrapper) for a given asset path.
  Future<QLYamlNode> loadNode(String assetPath,
      {bool useCache = true, Map<String, String>? extraEnv}) async {
    final raw = await load(assetPath, useCache: useCache, extraEnv: extraEnv);
    return QLYamlNode.fromRaw(raw);
  }

  /// Parse a raw YAML/JSON string directly (no asset loading).
  /// Useful for server-delivered content.
  Future<Map<String, dynamic>> parseString(
    String rawData, {
    String? debugPath,
    Map<String, dynamic>? parentContext,
  }) async {
    if (rawData.isEmpty) return const <String, dynamic>{};

    final int hash = rawData.hashCode ^ (debugPath?.hashCode ?? 0);
    final cached = _resolvedCache.get(hash);
    if (cached != null) return cached;

    final parsed = await _parseRaw(rawData);
    final resolved = _resolveEnvInterpolation(parsed, QLYamlEnv.snapshot);
    final map = _toStringMap(resolved);
    _resolvedCache.put(hash, map, weight: rawData.length + 128);
    return map;
  }

  /// Clear all caches (useful for hot-reload scenarios).
  void clearCaches() {
    _resolvedCache.clear();
    _rawStringCache.clear();
    _inFlight.clear();
  }

  void clearCache() => clearCaches();

  /// Warm frequently-accessed files in parallel.
  Future<void> warmAll(List<String> assetPaths) async {
    await Future.wait(assetPaths.map((p) => load(p)));
  }

  // ── Internal Load Pipeline ─────────────────────────────────────────────────

  Future<Map<String, dynamic>> _loadInternal(
    String path, {
    required _ImportFrame frame,
    bool useCache = true,
    Map<String, String>? extraEnv,
  }) async {
    // 1. Load raw string
    final String raw = await _loadRawString(path, useCache: useCache);

    // 2. Compute content hash (path + content for cache key)
    final int hash = Object.hash(path, raw.hashCode);

    // 3. Check resolved cache
    if (useCache) {
      final cached = _resolvedCache.get(hash);
      if (cached != null) return cached;
    }

    // 4. Parse YAML/JSON — offload to Isolate for large files
    final dynamic parsed = raw.length > 8192 && !kIsWeb
        ? await QLIsolateBridge.safeRun(() => _parseSync(raw, path))
        : _parseSync(raw, path);

    // 5. Resolve $import: directives recursively
    final dynamic withImports =
        await _resolveImports(parsed, frame, useCache: useCache);

    // 6. Env interpolation
    final allEnv = {
      ...QLYamlEnv.snapshot,
      if (extraEnv != null) ...extraEnv,
    };
    final dynamic withEnv = _resolveEnvInterpolation(withImports, allEnv);

    // 7. Convert to strong-typed Map<String, dynamic>
    final Map<String, dynamic> result = _toStringMap(withEnv);

    // 8. Cache the result
    if (useCache) {
      _resolvedCache.put(hash, result,
          weight: raw.length + QLRuntimeCacheSizer.estimate(result));
    }

    return result;
  }

  // ── Raw String Loader ──────────────────────────────────────────────────────

  Future<String> _loadRawString(String path, {bool useCache = true}) async {
    if (useCache) {
      final cached = _rawStringCache.get(path);
      if (cached != null) return cached;
    }

    try {
      String raw;

      // 🚀 THE WEB CACHE-BUSTER FIX:
      // Bypass rootBundle on Flutter Web in Debug mode to defeat Chrome's aggressive HTTP cache.
      if (kIsWeb && kDebugMode) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        // Fetch directly from the local dev server with a cache-busting query parameter
        final response = await http.get(Uri.parse('assets/$path?v=$timestamp'));
        if (response.statusCode != 200) {
          throw Exception('HTTP ${response.statusCode}');
        }
        // Ensure we decode as UTF-8
        raw = utf8.decode(response.bodyBytes);
      } else {
        // Standard native/production loading
        raw = await rootBundle.loadString(path, cache: false);
      }

      if (useCache) {
        _rawStringCache.put(path, raw, weight: raw.length * 2);
      }
      return raw;
    } catch (e) {
      throw QuantumYamlException('Failed to load asset "$path": $e',
          sourcePath: path);
    }
  }

  // ── Parser — Sync, safe for both Isolate and main thread ──────────────────

  static dynamic _parseSync(String raw, String debugPath) {
    if (raw.trim().isEmpty) return <String, dynamic>{};
    final ext = debugPath.split('.').last.toLowerCase();
    try {
      if (ext == 'json') {
        return jsonDecode(raw);
      } else {
        // yaml + yml
        final doc = loadYaml(raw);
        return _yamlToNative(doc);
      }
    } catch (e) {
      throw QuantumYamlException('Parse error in "$debugPath": $e',
          sourcePath: debugPath);
    }
  }

  Future<dynamic> _parseRaw(String raw) async {
    if (raw.trim().startsWith('{') || raw.trim().startsWith('[')) {
      return jsonDecode(raw);
    }
    return _yamlToNative(loadYaml(raw));
  }

  /// Convert YamlMap/YamlList to standard Dart types.
  static dynamic _yamlToNative(dynamic value) {
    if (value is YamlMap) {
      final map = <String, dynamic>{};
      for (final entry in value.entries) {
        map[entry.key.toString()] = _yamlToNative(entry.value);
      }
      return map;
    }
    if (value is YamlList) {
      return value.map(_yamlToNative).toList();
    }
    return value;
  }

  // ── $import: Resolver ──────────────────────────────────────────────────────

  static const String _kImport = r'$import';
  static const String _kOverride = r'$override';
  static const String _kMerge = r'$merge';

  Future<dynamic> _resolveImports(
    dynamic node,
    _ImportFrame frame, {
    bool useCache = true,
  }) async {
    if (node is Map) {
      // Check if this map IS an import directive
      if (node.containsKey(_kImport)) {
        return _resolveImportDirective(node, frame, useCache: useCache);
      }

      // Resolve all values in parallel
      final Map<String, dynamic> result = {};
      final List<String> keys = node.keys.map((k) => k.toString()).toList();
      final List<Future<dynamic>> futures = keys.map((k) {
        return _resolveImports(node[k], frame, useCache: useCache);
      }).toList();

      final List<dynamic> resolved = await Future.wait(futures);
      for (int i = 0; i < keys.length; i++) {
        result[keys[i]] = resolved[i];
      }
      return result;
    }

    if (node is List) {
      final List<Future<dynamic>> futures = node.map((item) {
        return _resolveImports(item, frame, useCache: useCache);
      }).toList();
      final List<dynamic> resolved = await Future.wait(futures);

      // Flatten: if an import returns a list, merge it inline
      final List<dynamic> flat = [];
      for (int i = 0; i < node.length; i++) {
        final original = node[i];
        final resolvedItem = resolved[i];
        // If original was an import directive and result is a list, flatten
        if (original is Map &&
            original.containsKey(_kImport) &&
            resolvedItem is List) {
          flat.addAll(resolvedItem);
        } else {
          flat.add(resolvedItem);
        }
      }
      return flat;
    }

    return node;
  }

  Future<dynamic> _resolveImportDirective(
    Map<dynamic, dynamic> node,
    _ImportFrame frame, {
    bool useCache = true,
  }) async {
    final dynamic importPath = node[_kImport];
    if (importPath == null) return <String, dynamic>{};

    final String resolvedPath =
        _resolveRelativePath(frame.path, importPath.toString());

    // Circular import detection
    if (frame.contains(resolvedPath)) {
      throw QuantumYamlException('Circular import detected: "$resolvedPath"',
          sourcePath: frame.path,
          importChain: frame.chain + ' → $resolvedPath');
    }

    final _ImportFrame childFrame = _ImportFrame(resolvedPath, frame);

    // Load the imported file
    final Map<String, dynamic> importedRaw = await _loadInternal(resolvedPath,
        frame: childFrame, useCache: useCache);

    // 🚀 THE FOREVER FIX: Unwrap raw lists previously forced into {'_root': [...]} maps
    dynamic imported = importedRaw;
    if (importedRaw.containsKey('_root') && importedRaw.length == 1) {
      imported = importedRaw['_root'];
    }

    // Apply $override on top of imported (only works if imported is a Map)
    final dynamic overrides = node[_kOverride];
    if (overrides is Map && imported is Map) {
      final Map<String, dynamic> merged = Map<String, dynamic>.from(imported);
      overrides.forEach((k, v) => merged[k.toString()] = v);
      return merged;
    }

    // Apply $merge (deep merge, imported wins on non-maps)
    final dynamic mergeWith = node[_kMerge];
    if (mergeWith is Map && imported is Map) {
      return _deepMerge(Map<String, dynamic>.from(imported),
          Map<String, dynamic>.from(mergeWith));
    }

    return imported;
  }

  /// Deep merge: [base] values are overridden by [overlay] values.
  static Map<String, dynamic> _deepMerge(
      Map<String, dynamic> base, Map<String, dynamic> overlay) {
    final Map<String, dynamic> result = Map<String, dynamic>.from(base);
    overlay.forEach((key, value) {
      if (value is Map && result[key] is Map) {
        result[key] = _deepMerge(Map<String, dynamic>.from(result[key] as Map),
            Map<String, dynamic>.from(value));
      } else {
        result[key] = value;
      }
    });
    return result;
  }

  /// Resolve a relative asset path.
  static String _resolveRelativePath(String fromPath, String importPath) {
    // 🚀 THE FOREVER FIX: Absolute paths (starting with /) drop the slash and normalize.
    // Anything else parses directory traversal starting from the current directory.
    if (importPath.startsWith('/')) return _normalise(importPath.substring(1));

    final List<String> baseParts = fromPath.split('/');
    if (baseParts.isNotEmpty) baseParts.removeLast(); // remove filename

    final List<String> importParts = importPath.split('/');
    final List<String> parts = List<String>.from(baseParts);

    for (final part in importParts) {
      if (part == '..') {
        if (parts.isNotEmpty) parts.removeLast();
      } else if (part != '.') {
        parts.add(part);
      }
    }
    return _normalise(parts.join('/'));
  }

  static String _normalise(String path) {
    // Ensure it has an extension; default to .yaml
    final hasExt = path.contains('.') &&
        (path.endsWith('.yaml') ||
            path.endsWith('.yml') ||
            path.endsWith('.json'));
    if (!hasExt) return '$path.yaml';
    return path;
  }

  // ── Env Interpolation ──────────────────────────────────────────────────────

  /// Recursively substitute `{{env.VAR}}` and `{{env.VAR | default: VALUE}}`
  static dynamic _resolveEnvInterpolation(
      dynamic node, Map<String, String> env) {
    if (node is String) return _interpolateEnvString(node, env);
    if (node is Map) {
      final result = <String, dynamic>{};
      node.forEach((k, v) {
        result[k.toString()] = _resolveEnvInterpolation(v, env);
      });
      return result;
    }
    if (node is List) {
      return node.map((v) => _resolveEnvInterpolation(v, env)).toList();
    }
    return node;
  }

  static final RegExp _envPattern =
      RegExp(r'\{\{env\.([^}|]+?)(?:\s*\|\s*default:\s*([^}]*))?\}\}');

  static String _interpolateEnvString(String input, Map<String, String> env) {
    if (!input.contains('{{env.')) return input;
    return input.replaceAllMapped(_envPattern, (match) {
      final key = match.group(1)!.trim();
      final fallback = match.group(2)?.trim() ?? '';
      return env[key] ?? fallback;
    });
  }

  // ── Type Conversion ────────────────────────────────────────────────────────

  static Map<String, dynamic> _toStringMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value as Map);
    // If top-level is a list or scalar, wrap it
    return {'_root': value};
  }
}

// ─────────────────────────────────────────────────────────────────────── §6 ─
//  CONFIG EXTRACTORS — Type-safe config helpers
// ────────────────────────────────────────────────────────────────────────────

/// Utility class for extracting typed config from raw Map.
abstract final class QLYamlConfig {
  // ── Primitives ──────────────────────────────────────────────────────────────

  static String string(Map<String, dynamic> map, String key,
      {String fallback = ''}) {
    final v = _dig(map, key);
    if (v == null) return fallback;
    return v.toString();
  }

  static int integer(Map<String, dynamic> map, String key, {int fallback = 0}) {
    final v = _dig(map, key);
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    // 🚀 THE FOREVER FIX: Failover to double parsing, then convert to int to allow '99.9' parsing.
    return int.tryParse(v.toString()) ??
        double.tryParse(v.toString())?.toInt() ??
        fallback;
  }

  static double number(Map<String, dynamic> map, String key,
      {double fallback = 0.0}) {
    final v = _dig(map, key);
    if (v == null) return fallback;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  static bool boolean(Map<String, dynamic> map, String key,
      {bool fallback = false}) {
    final v = _dig(map, key);
    if (v == null) return fallback;
    if (v is bool) return v;

    final s = v.toString().trim().toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes' || s == 'on') return true;
    if (s == 'false' || s == '0' || s == 'no' || s == 'off') return false;

    return fallback;
  }

  static Map<String, dynamic> map(Map<String, dynamic> src, String key,
      {Map<String, dynamic> fallback = const {}}) {
    final v = _dig(src, key);
    if (v is Map) return Map<String, dynamic>.from(v);
    return fallback;
  }

  static List<dynamic> list(Map<String, dynamic> src, String key,
      {List<dynamic> fallback = const []}) {
    final v = _dig(src, key);
    if (v is List) return List<dynamic>.from(v);
    if (v != null) return [v]; // scalar → single-element list
    return fallback;
  }

  static List<String> stringList(Map<String, dynamic> src, String key,
      {List<String> fallback = const []}) {
    return list(src, key, fallback: fallback)
        .map((v) => v.toString())
        .toList(growable: false);
  }

  // ── Deep path navigation using dot notation ────────────────────────────────

  static dynamic _dig(Map<String, dynamic> map, String key) {
    if (!key.contains('.')) return map[key];
    final parts = key.split('.');
    dynamic current = map;
    for (final part in parts) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current;
  }
}

// ─────────────────────────────────────────────────────────────────────── §7 ─
//  YAML APP CONFIG MODEL
// ────────────────────────────────────────────────────────────────────────────

/// Parsed, fully-resolved representation of APP.yaml.
class QLAppYamlConfig {
  // ── App identity ───────────────────────────────────────────────────────────
  final String appName;
  final String title;
  final String locale;
  final String version;

  // ── Theme ──────────────────────────────────────────────────────────────────
  final Map<String, dynamic> theme;

  // ── Router ─────────────────────────────────────────────────────────────────
  final String initialRoute;
  final String pagesDir;
  final String? notFoundPage;
  final List<Map<String, dynamic>> globalGuards;

  // ── VM ─────────────────────────────────────────────────────────────────────
  final int workerThreads;
  final int simdArenaCapacity;

  // ── Telemetry ──────────────────────────────────────────────────────────────
  final bool telemetryEnabled;
  final bool frameMonitor;

  // ── Domains ────────────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> domains;

  // ── Initial State ──────────────────────────────────────────────────────────
  final Map<String, dynamic> state;

  // ── Macros / Schemas / Pipes / Actions (global) ───────────────────────────
  final Map<String, dynamic> macros;
  final Map<String, dynamic> schemas;
  final Map<String, dynamic> pipes;
  final Map<String, dynamic> actions;

  // ── SDUI ───────────────────────────────────────────────────────────────────
  final Map<String, dynamic> sdui;

  // ── Raw full config (for custom extensions) ────────────────────────────────
  final Map<String, dynamic> raw;

  const QLAppYamlConfig({
    required this.appName,
    this.title = '',
    this.locale = 'en',
    this.version = '1.0.0',
    this.theme = const {},
    this.initialRoute = '/',
    this.pagesDir = 'pages',
    this.notFoundPage,
    this.globalGuards = const [],
    this.workerThreads = 4,
    this.simdArenaCapacity = 4096,
    this.telemetryEnabled = true,
    this.frameMonitor = true,
    this.domains = const [],
    this.state = const {},
    this.macros = const {},
    this.schemas = const {},
    this.pipes = const {},
    this.actions = const {},
    this.sdui = const {},
    this.raw = const {},
  });

  factory QLAppYamlConfig.fromMap(Map<String, dynamic> map) {
    final appSection = QLYamlConfig.map(map, 'app');
    final routerSection = QLYamlConfig.map(map, 'router');
    final vmSection = QLYamlConfig.map(map, 'vm');
    final telemetrySection = QLYamlConfig.map(map, 'telemetry');

    return QLAppYamlConfig(
      appName: QLYamlConfig.string(appSection, 'name',
          fallback: QLYamlConfig.string(map, 'name', fallback: 'QuantumApp')),
      title: QLYamlConfig.string(appSection, 'title',
          fallback: QLYamlConfig.string(map, 'title', fallback: '')),
      locale: QLYamlConfig.string(appSection, 'locale', fallback: 'en'),
      version: QLYamlConfig.string(appSection, 'version', fallback: '1.0.0'),
      theme: QLYamlConfig.map(map, 'theme'),
      initialRoute:
          QLYamlConfig.string(routerSection, 'initialRoute', fallback: '/'),
      pagesDir:
          QLYamlConfig.string(routerSection, 'pagesDir', fallback: 'pages'),
      notFoundPage: () {
        final v = routerSection['notFound'];
        return v?.toString();
      }(),
      globalGuards: QLYamlConfig.list(routerSection, 'globalGuards')
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList(growable: false),
      workerThreads:
          QLYamlConfig.integer(vmSection, 'workerThreads', fallback: 4),
      simdArenaCapacity:
          QLYamlConfig.integer(vmSection, 'simdArenaCapacity', fallback: 4096),
      telemetryEnabled:
          QLYamlConfig.boolean(telemetrySection, 'enabled', fallback: true),
      frameMonitor: QLYamlConfig.boolean(telemetrySection, 'frameMonitor',
          fallback: true),
      domains: QLYamlConfig.list(map, 'domains')
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList(growable: false),
      state: QLYamlConfig.map(map, 'state'),
      macros: QLYamlConfig.map(map, 'macros'),
      schemas: QLYamlConfig.map(map, 'schemas'),
      pipes: QLYamlConfig.map(map, 'pipes'),
      actions: QLYamlConfig.map(map, 'actions'),
      sdui: QLYamlConfig.map(map, 'sdui'),
      raw: map,
    );
  }

  /// Load from an asset path (resolves all $import: directives first).
  static Future<QLAppYamlConfig> loadFromAsset(String assetPath) async {
    final map = await QuantumYamlEngine.instance.load(assetPath);
    return QLAppYamlConfig.fromMap(map);
  }
}

// ─────────────────────────────────────────────────────────────────────── §8 ─
//  YAML THEME CONFIG
// ────────────────────────────────────────────────────────────────────────────

/// Extracts strongly-typed theme tokens from YAML.
class QLYamlThemeConfig {
  final Map<String, dynamic> colors;
  final Map<String, dynamic> typography;
  final Map<String, dynamic> spacing;
  final Map<String, dynamic> breakpoints;
  final Map<String, dynamic> shadows;
  final Map<String, dynamic> radii;
  final String mode; // 'light' | 'dark' | 'system'
  final Map<String, dynamic> raw;

  const QLYamlThemeConfig({
    this.colors = const {},
    this.typography = const {},
    this.spacing = const {},
    this.breakpoints = const {},
    this.shadows = const {},
    this.radii = const {},
    this.mode = 'system',
    this.raw = const {},
  });

  factory QLYamlThemeConfig.fromMap(Map<String, dynamic> map) {
    return QLYamlThemeConfig(
      colors: QLYamlConfig.map(map, 'colors'),
      typography: QLYamlConfig.map(map, 'typography'),
      spacing: QLYamlConfig.map(map, 'spacing'),
      breakpoints: QLYamlConfig.map(map, 'breakpoints'),
      shadows: QLYamlConfig.map(map, 'shadows'),
      radii: QLYamlConfig.map(map, 'radii'),
      mode: QLYamlConfig.string(map, 'mode', fallback: 'system'),
      raw: map,
    );
  }

  static Future<QLYamlThemeConfig> loadFromAsset(String assetPath) async {
    final map = await QuantumYamlEngine.instance.load(assetPath);
    return QLYamlThemeConfig.fromMap(map);
  }
}

// ─────────────────────────────────────────────────────────────────────── §9 ─
//  YAML PAGE / SCREEN CONFIG  (per-page YAML model)
// ────────────────────────────────────────────────────────────────────────────

/// Semantic types a YAML file can declare.
enum QLYamlSemanticType {
  screen,
  page,
  component,
  widget,
  layout,
  modal,
  drawer,
  overlay,
  fragment,
  template,
  unknown,
}

/// Parsed model of a per-page YAML file.
class QLPageYamlConfig {
  final QLYamlSemanticType semanticType;

  // ── Metadata ───────────────────────────────────────────────────────────────
  final String? metaTitle;
  final String? metaDescription;
  final String? metaKeywords;
  final String? metaOgImage;
  final Map<String, String> customMeta;

  // ── URL override ───────────────────────────────────────────────────────────
  final String? urlPattern; // regex
  final List<String> captureGroups;

  // ── Data fetching ──────────────────────────────────────────────────────────
  final Map<String, dynamic>? serverProps;
  final Map<String, dynamic>? staticProps;
  final Map<String, dynamic>? initialProps;
  final List<String> staticPaths;

  // ── State / Schemas / Pipelines ────────────────────────────────────────────
  final Map<String, dynamic> state;
  final Map<String, dynamic> schemas;
  final Map<String, dynamic> pipelines;

  // ── Guards ─────────────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> guards;

  // ── Macros ─────────────────────────────────────────────────────────────────
  final Map<String, dynamic> macros;

  // ── Default props ──────────────────────────────────────────────────────────
  final Map<String, dynamic> defaultProps;

  // ── UI Blueprint ──────────────────────────────────────────────────────────
  final dynamic ui; // raw AST (not yet compiled)

  // ── Layout slot ───────────────────────────────────────────────────────────
  final String? layoutSlot;

  // ── Transition ────────────────────────────────────────────────────────────
  final String transition;
  final int transitionDurationMs;

  // ── Full raw map ──────────────────────────────────────────────────────────
  final Map<String, dynamic> raw;

  const QLPageYamlConfig({
    this.semanticType = QLYamlSemanticType.page,
    this.metaTitle,
    this.metaDescription,
    this.metaKeywords,
    this.metaOgImage,
    this.customMeta = const {},
    this.urlPattern,
    this.captureGroups = const [],
    this.serverProps,
    this.staticProps,
    this.initialProps,
    this.staticPaths = const [],
    this.state = const {},
    this.schemas = const {},
    this.pipelines = const {},
    this.guards = const [],
    this.macros = const {},
    this.defaultProps = const {},
    this.ui,
    this.layoutSlot,
    this.transition = 'slideRight',
    this.transitionDurationMs = 380,
    this.raw = const {},
  });

  factory QLPageYamlConfig.fromMap(Map<String, dynamic> map) {
    final metaSection = QLYamlConfig.map(map, 'meta');
    final routeSection = QLYamlConfig.map(map, 'route');

    return QLPageYamlConfig(
      semanticType: _parseSemanticType(QLYamlConfig.string(map, 'type')),
      metaTitle: metaSection['title']?.toString(),
      metaDescription: metaSection['description']?.toString(),
      metaKeywords: metaSection['keywords']?.toString(),
      metaOgImage: metaSection['ogImage']?.toString(),
      customMeta: Map<String, String>.from(
          QLYamlConfig.map(metaSection, 'custom')
              .map((k, v) => MapEntry(k, v.toString()))),
      urlPattern: routeSection['urlPattern']?.toString() ??
          (map['urlPattern']?.toString()),
      captureGroups: QLYamlConfig.stringList(routeSection, 'captureGroups'),
      serverProps: map['serverProps'] is Map
          ? Map<String, dynamic>.from(map['serverProps'] as Map)
          : null,
      staticProps: map['staticProps'] is Map
          ? Map<String, dynamic>.from(map['staticProps'] as Map)
          : null,
      initialProps: map['initialProps'] is Map
          ? Map<String, dynamic>.from(map['initialProps'] as Map)
          : null,
      staticPaths: QLYamlConfig.stringList(map, 'staticPaths'),
      state: QLYamlConfig.map(map, 'state'),
      schemas: QLYamlConfig.map(map, 'schemas'),
      pipelines: QLYamlConfig.map(map, 'pipelines'),
      guards: QLYamlConfig.list(map, 'guards')
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList(growable: false),
      macros: QLYamlConfig.map(map, 'macros'),
      defaultProps: QLYamlConfig.map(map, 'defaultProps'),
      ui: map['ui'] ?? map['view'] ?? map['template'],
      layoutSlot: map['layoutSlot']?.toString(),
      transition: QLYamlConfig.string(routeSection, 'transition',
          fallback: 'slideRight'),
      transitionDurationMs:
          QLYamlConfig.integer(routeSection, 'transitionMs', fallback: 380),
      raw: map,
    );
  }

  static QLYamlSemanticType _parseSemanticType(String raw) {
    return switch (raw.toLowerCase()) {
      'screen' => QLYamlSemanticType.screen,
      'page' => QLYamlSemanticType.page,
      'component' => QLYamlSemanticType.component,
      'widget' => QLYamlSemanticType.widget,
      'layout' => QLYamlSemanticType.layout,
      'modal' => QLYamlSemanticType.modal,
      'drawer' => QLYamlSemanticType.drawer,
      'overlay' => QLYamlSemanticType.overlay,
      'fragment' => QLYamlSemanticType.fragment,
      'template' => QLYamlSemanticType.template,
      _ => QLYamlSemanticType.page,
    };
  }

  static Future<QLPageYamlConfig> loadFromAsset(String assetPath) async {
    final map = await QuantumYamlEngine.instance.load(assetPath);
    return QLPageYamlConfig.fromMap(map);
  }
}

// ─────────────────────────────────────────────────────────────────────── §10 ─
//  GLOBAL MACROS / SCHEMAS / PIPES from YAML
// ────────────────────────────────────────────────────────────────────────────

/// Applies macros from YAML map to QuantumVM.
void applyYamlMacros(Map<String, dynamic> macros) {
  if (macros.isEmpty) return;
  macros.forEach((name, def) {
    if (def is Map) {
      QJsonTemplateEngine_D.define(
          <String, dynamic>{'name': name, ...Map<String, dynamic>.from(def)});
    }
  });
}

/// Applies schemas from YAML map to QLSchemaRegistry.
void applyYamlSchemas(Map<String, dynamic> schemas) {
  if (schemas.isEmpty) return;
  schemas.forEach((name, def) {
    if (def is Map) {
      QLSchemaRegistry.instance
          .registerRaw(name, Map<String, dynamic>.from(def));
    }
  });
}

/// Applies custom pipes from YAML definitions.
/// Only supports pipes that reference registered Dart transform names.
void applyYamlPipes(Map<String, dynamic> pipes) {
  // Pipes defined in YAML are declarative references, not code.
  // They are registered for documentation purposes; actual transforms
  // must be registered in Dart. This is a hook for future expansion.
  if (kDebugMode && pipes.isNotEmpty) {
    debugPrint(
        '[QuantumYaml] ${pipes.length} pipe definitions loaded (transforms must be registered in Dart).');
  }
}

/// Applies initial state from YAML to the QuantumVM global store.
void applyYamlState(Map<String, dynamic> state) {
  if (state.isEmpty) return;
  QuantumVM.instance.store.merge(state);
}
