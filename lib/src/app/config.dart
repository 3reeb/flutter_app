/*
 * ============================================================================
 * File: config.dart
 * 
 * Description:
 * Provides the single-source configuration schema for the Quantum framework. 
 * This module orchestrates loading, merging, and resolving configuration data 
 * from various sources including local assets, file system, inline data, and 
 * remote HTTP endpoints. It supports build-time overlays, deep nested merging, 
 * security/vault-friendly fields, and caching policies.
 * 
 * Key Components:
 * - OmniShellConfigSource: Abstract base class representing a configuration source.
 * - OmniShellConfigRoot: The root configuration structure containing all app settings.
 * - QuantumBuildOverlay: Handles build-time defined environment overrides.
 * - OmniShellConfigSecurityPolicy: Enforces locked and sensitive paths for security.
 * 
 * Dependencies/Relationships:
 * Relies on quantum_yaml_engine for YAML parsing, quantum_http_transport for 
 * remote fetching, and integrates closely with app booting components.
 * 
 * Notes:
 * This file is highly framework-level and declarative. It heavily utilizes 
 * immutability to ensure resolved snapshots remain intact during the app's lifecycle.
 * ============================================================================
 */
// ════════════════════════════════════════════════════════════════════════════
// config.dart
//
// Single-source config schema for the Quantum framework.
// - local YAML / JSON sources
// - remote YAML / JSON sources
// - deep nested overrides
// - build-time locked fields
// - secure/vault-friendly fields
// - immutable resolved snapshots
// - source provenance and debug trace
//
// This file is intentionally framework-level and declarative. It does not
// duplicate the existing YAML parser; it composes it.
// ════════════════════════════════════════════════════════════════════════════

library quantum_config;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../foundation/quantum_yaml_engine.dart';
import 'package:quantum_layout/src/runtime/api/network_shell.dart';
import 'package:quantum_layout/src/runtime/api/network.dart';

import 'quantum_app_boot.dart';
import 'quantum_boot_schema.dart';
import 'quantum_http_transport.dart';
import 'quantum_file_router.dart';

// consider to remove this in future
import '../ui/quantum_navigation_engine.dart';
// ────────────────────────────────────────────────────────────────────────────
// Build-time defines
// ────────────────────────────────────────────────────────────────────────────

@immutable
class QuantumBuildDefines {
  static const String apiUrl =
      String.fromEnvironment('QUANTUM_API_URL', defaultValue: '');
  static const String socketUrl =
      String.fromEnvironment('QUANTUM_SOCKET_URL', defaultValue: '');
  static const String environment =
      String.fromEnvironment('QUANTUM_ENV', defaultValue: 'production');
  static const String clientSecret =
      String.fromEnvironment('QUANTUM_CLIENT_SECRET', defaultValue: '');
  static const String remoteConfigSecret =
      String.fromEnvironment('QUANTUM_REMOTE_CONFIG_SECRET', defaultValue: '');
  static const bool strictConfig =
      bool.fromEnvironment('QUANTUM_STRICT_CONFIG', defaultValue: true);
  static const bool allowUnsignedRemoteConfig = bool.fromEnvironment(
      'QUANTUM_ALLOW_UNSIGNED_REMOTE_CONFIG',
      defaultValue: false);

  const QuantumBuildDefines._();
}

@immutable
class QuantumBuildOverlay {
  final Map<String, dynamic> data;
  final Set<String> lockedPaths;

  const QuantumBuildOverlay({
    required this.data,
    required this.lockedPaths,
  });

  factory QuantumBuildOverlay.fromEnv() {
    final data = <String, dynamic>{};
    final locked = <String>{};

    if (QuantumBuildDefines.apiUrl.isNotEmpty) {
      data['api'] = <String, dynamic>{
        'baseUrl': QuantumBuildDefines.apiUrl,
      };
      locked.add('api.baseUrl');
    }

    if (QuantumBuildDefines.socketUrl.isNotEmpty) {
      data['api'] ??= <String, dynamic>{};
      (data['api'] as Map<String, dynamic>)['socketUrl'] =
          QuantumBuildDefines.socketUrl;
      locked.add('api.socketUrl');
    }

    if (QuantumBuildDefines.environment.isNotEmpty) {
      data['runtime'] = <String, dynamic>{
        'environment': QuantumBuildDefines.environment,
      };
      locked.add('runtime.environment');
    }

    if (QuantumBuildDefines.clientSecret.isNotEmpty) {
      data['security'] = <String, dynamic>{
        'clientSecret': QuantumBuildDefines.clientSecret,
      };
      locked.add('security.clientSecret');
    }

    return QuantumBuildOverlay(data: data, lockedPaths: locked);
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Source model
// ────────────────────────────────────────────────────────────────────────────

enum OmniShellConfigSourceKind {
  inline,
  asset,
  file,
  http,
  custom,
}

enum OmniShellConfigListMergeMode {
  replace,
  concat,
  uniqueConcat,
}

@immutable
class OmniShellConfigSourceResult {
  final String sourceId;
  final OmniShellConfigSourceKind kind;
  final Map<String, dynamic> data;
  final String contentHash;
  final DateTime fetchedAt;
  final String? etag;
  final String? version;
  final bool fromCache;
  final Map<String, dynamic> meta;

  const OmniShellConfigSourceResult({
    required this.sourceId,
    required this.kind,
    required this.data,
    required this.contentHash,
    required this.fetchedAt,
    this.etag,
    this.version,
    this.fromCache = false,
    this.meta = const {},
  });
}

typedef OmniShellConfigSourceLoader = Future<OmniShellConfigSourceResult>
    Function(
  OmniShellConfigSource source,
  OmniShellConfigSourceContext context,
);

@immutable
class OmniShellConfigSourceContext {
  final QuantumYamlEngine yaml;
  final QuantumHttpTransport http;
  final Map<String, String> env;
  final SecureStorageDelegate? secureVault; // <-- CHANGED HERE
  final bool useCache;

  const OmniShellConfigSourceContext({
    required this.yaml,
    required this.http,
    required this.env,
    required this.secureVault,
    required this.useCache,
  });
}

@immutable
abstract class OmniShellConfigSource {
  final String id;
  final OmniShellConfigSourceKind kind;
  final int priority;
  final bool enabled;
  final Duration? ttl;
  final Map<String, String> headers;
  final bool required;
  final bool allowOverrides;

  const OmniShellConfigSource({
    required this.id,
    required this.kind,
    this.priority = 0,
    this.enabled = true,
    this.ttl,
    this.headers = const {},
    this.required = true,
    this.allowOverrides = true,
  });

  Future<OmniShellConfigSourceResult> load(
      OmniShellConfigSourceContext context);

  String get stableKey => '$kind::$id::$priority';
}

@immutable
class QuantumInlineConfigSource extends OmniShellConfigSource {
  final Map<String, dynamic> value;

  const QuantumInlineConfigSource({
    required super.id,
    required this.value,
    super.priority = 0,
    super.enabled = true,
    super.required = true,
    super.allowOverrides = true,
  }) : super(kind: OmniShellConfigSourceKind.inline);

  @override
  Future<OmniShellConfigSourceResult> load(
      OmniShellConfigSourceContext context) async {
    final normalized = _normalizeMap(value);
    final hash = _sha256OfMap(normalized);
    return OmniShellConfigSourceResult(
      sourceId: id,
      kind: kind,
      data: normalized,
      contentHash: hash,
      fetchedAt: DateTime.now(),
      version: hash,
    );
  }
}

@immutable
class QuantumAssetConfigSource extends OmniShellConfigSource {
  final String assetPath;
  final Map<String, String>? extraEnv;

  const QuantumAssetConfigSource({
    required super.id,
    required this.assetPath,
    this.extraEnv,
    super.priority = 0,
    super.enabled = true,
    super.ttl,
    super.headers = const {},
    super.required = true,
    super.allowOverrides = true,
  }) : super(kind: OmniShellConfigSourceKind.asset);

  @override
  Future<OmniShellConfigSourceResult> load(
      OmniShellConfigSourceContext context) async {
    final raw = await context.yaml.load(
      assetPath,
      useCache: context.useCache,
      extraEnv: extraEnv,
    );
    final hash = _sha256OfMap(raw);
    return OmniShellConfigSourceResult(
      sourceId: id,
      kind: kind,
      data: _normalizeMap(raw),
      contentHash: hash,
      fetchedAt: DateTime.now(),
      version: hash,
    );
  }
}

@immutable
class QuantumFileConfigSource extends OmniShellConfigSource {
  final String filePath;
  final Encoding encoding;

  const QuantumFileConfigSource({
    required super.id,
    required this.filePath,
    this.encoding = utf8,
    super.priority = 0,
    super.enabled = true,
    super.ttl,
    super.headers = const {},
    super.required = true,
    super.allowOverrides = true,
  }) : super(kind: OmniShellConfigSourceKind.file);

  @override
  Future<OmniShellConfigSourceResult> load(
      OmniShellConfigSourceContext context) async {
    final raw = await File(filePath).readAsString(encoding: encoding);
    final parsed = await context.yaml.parseString(raw, debugPath: filePath);
    final hash = _sha256OfMap(parsed);
    return OmniShellConfigSourceResult(
      sourceId: id,
      kind: kind,
      data: _normalizeMap(parsed),
      contentHash: hash,
      fetchedAt: DateTime.now(),
      version: hash,
    );
  }
}

@immutable
class QuantumHttpConfigSource extends OmniShellConfigSource {
  final Uri uri;
  final String method;
  final Object? body;
  final Duration timeout;
  final bool cacheByEtag;
  final String? expectedSha256;
  final OmniShellConfigSourceLoader? customLoader;

  const QuantumHttpConfigSource({
    required super.id,
    required this.uri,
    this.method = 'GET',
    this.body,
    this.timeout = const Duration(seconds: 10),
    this.cacheByEtag = true,
    this.expectedSha256,
    this.customLoader,
    super.priority = 0,
    super.enabled = true,
    super.ttl,
    super.headers = const {},
    super.required = true,
    super.allowOverrides = true,
  }) : super(kind: OmniShellConfigSourceKind.http);

  @override
  Future<OmniShellConfigSourceResult> load(
      OmniShellConfigSourceContext context) async {
    if (customLoader != null) {
      return customLoader!(this, context);
    }

    final request = await context.http.openUrl(method.toUpperCase(), uri);

    // Use index map assignment rather than .set()
    headers.forEach((key, value) => request.headers[key] = value);
    if (cacheByEtag && _etagBySource.containsKey(stableKey)) {
      request.headers[HttpHeaders.ifNoneMatchHeader] =
          _etagBySource[stableKey]!;
    }
    if (body != null) {
      final encoded = body is String ? body as String : jsonEncode(body);
      request.add(utf8.encode(encoded));
    }

    final response = await request.close().timeout(timeout);
    if (response.statusCode == HttpStatus.notModified &&
        _cachedBySource.containsKey(stableKey)) {
      return _cachedBySource[stableKey]!;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OmniShellConfigException(
        'Remote config request failed',
        sourceId: id,
        details: {'statusCode': response.statusCode, 'uri': uri.toString()},
      );
    }

    // Call response.text() directly instead of treating it as a Stream
    final raw = await response.text();
    final parsed =
        await context.yaml.parseString(raw, debugPath: uri.toString());
    final normalized = _normalizeMap(parsed);
    final hash = _sha256OfMap(normalized);

    if (expectedSha256 != null &&
        expectedSha256!.isNotEmpty &&
        expectedSha256 != hash) {
      throw OmniShellConfigException(
        'Remote config hash mismatch',
        sourceId: id,
        details: {'expected': expectedSha256, 'actual': hash},
      );
    }

    // Use map bracket notation to retrieve headers safely
    final etag =
        response.headers[HttpHeaders.etagHeader] ?? response.headers['etag'];
    final lastModified = response.headers[HttpHeaders.lastModifiedHeader] ??
        response.headers['last-modified'];

    final result = OmniShellConfigSourceResult(
      sourceId: id,
      kind: kind,
      data: normalized,
      contentHash: hash,
      fetchedAt: DateTime.now(),
      etag: etag,
      version: lastModified ?? hash,
      meta: <String, dynamic>{
        'statusCode': response.statusCode,
        'uri': uri.toString(),
      },
    );

    if (cacheByEtag && result.etag != null) {
      _etagBySource[stableKey] = result.etag!;
    }
    _cachedBySource[stableKey] = result;
    return result;
  }

  static final Map<String, String> _etagBySource = <String, String>{};
  static final Map<String, OmniShellConfigSourceResult> _cachedBySource =
      <String, OmniShellConfigSourceResult>{};
}

@immutable
class QuantumCustomConfigSource extends OmniShellConfigSource {
  final OmniShellConfigSourceLoader loader;

  const QuantumCustomConfigSource({
    required super.id,
    required this.loader,
    super.priority = 0,
    super.enabled = true,
    super.ttl,
    super.headers = const {},
    super.required = true,
    super.allowOverrides = true,
  }) : super(kind: OmniShellConfigSourceKind.custom);

  @override
  Future<OmniShellConfigSourceResult> load(
      OmniShellConfigSourceContext context) {
    return loader(this, context);
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Merge / lock / security policy
// ────────────────────────────────────────────────────────────────────────────

@immutable
class OmniShellConfigMergePolicy {
  final OmniShellConfigListMergeMode listMode;
  final bool deepMergeMaps;
  final bool mergeNulls;
  final bool allowNewKeys;
  final bool preferRemoteOnConflict;

  const OmniShellConfigMergePolicy({
    this.listMode = OmniShellConfigListMergeMode.replace,
    this.deepMergeMaps = true,
    this.mergeNulls = false,
    this.allowNewKeys = true,
    this.preferRemoteOnConflict = true,
  });
}

@immutable
class OmniShellConfigSecurityPolicy {
  final Set<String> lockedPaths;
  final Set<String> sensitivePaths;
  final bool requireBuildLockForSensitive;
  final bool requireSignedRemoteConfig;
  final bool allowUnsignedRemoteConfigInDebug;
  final bool persistEncryptedRemoteCache;
  final bool cacheSensitiveValuesInVault;
  final String? vaultNamespace;
  final String? remoteSignatureKeyEnv;
  final String? remoteEncryptionKeyEnv;

  const OmniShellConfigSecurityPolicy({
    this.lockedPaths = const <String>{},
    this.sensitivePaths = const <String>{},
    this.requireBuildLockForSensitive = true,
    this.requireSignedRemoteConfig = false,
    this.allowUnsignedRemoteConfigInDebug = true,
    this.persistEncryptedRemoteCache = true,
    this.cacheSensitiveValuesInVault = true,
    this.vaultNamespace,
    this.remoteSignatureKeyEnv,
    this.remoteEncryptionKeyEnv,
  });

  bool isLocked(String path) {
    for (final locked in lockedPaths) {
      if (path == locked || path.startsWith('$locked.')) return true;
    }
    return false;
  }

  bool isSensitive(String path) {
    for (final sensitive in sensitivePaths) {
      if (path == sensitive || path.startsWith('$sensitive.')) return true;
    }
    return false;
  }
}

@immutable
class OmniShellConfigCachePolicy {
  final bool enableMemoization;
  final Duration remoteTtl;
  final Duration localTtl;
  final int maxSnapshots;
  final bool singleFlight;
  final bool useSourceDigests;

  const OmniShellConfigCachePolicy({
    this.enableMemoization = true,
    this.remoteTtl = const Duration(minutes: 5),
    this.localTtl = const Duration(days: 3650),
    this.maxSnapshots = 4,
    this.singleFlight = true,
    this.useSourceDigests = true,
  });
}

// ────────────────────────────────────────────────────────────────────────────
// Typed sections
// ────────────────────────────────────────────────────────────────────────────

@immutable
class OmniShellConfigThemeSection {
  final String mode;
  final Map<String, dynamic> colors;
  final Map<String, dynamic> typography;
  final Map<String, dynamic> spacing;
  final Map<String, dynamic> breakpoints;
  final Map<String, dynamic> shadows;
  final Map<String, dynamic> radii;

  const OmniShellConfigThemeSection({
    this.mode = 'system',
    this.colors = const {},
    this.typography = const {},
    this.spacing = const {},
    this.breakpoints = const {},
    this.shadows = const {},
    this.radii = const {},
  });

  Map<String, dynamic> toLegacyMap() => <String, dynamic>{
        'mode': mode,
        if (colors.isNotEmpty) 'colors': colors,
        if (typography.isNotEmpty) 'typography': typography,
        if (spacing.isNotEmpty) 'spacing': spacing,
        if (breakpoints.isNotEmpty) 'breakpoints': breakpoints,
        if (shadows.isNotEmpty) 'shadows': shadows,
        if (radii.isNotEmpty) 'radii': radii,
      };
}

@immutable
class OmniShellConfigRouterSection {
  final String initialRoute;
  final String pagesDir;
  final String? notFoundPage;
  final List<Map<String, dynamic>> globalGuards;

  const OmniShellConfigRouterSection({
    this.initialRoute = '/',
    this.pagesDir = 'pages',
    this.notFoundPage,
    this.globalGuards = const [],
  });

  Map<String, dynamic> toLegacyMap() => <String, dynamic>{
        'initialRoute': initialRoute,
        'pagesDir': pagesDir,
        if (notFoundPage != null) 'notFound': notFoundPage,
        if (globalGuards.isNotEmpty) 'globalGuards': globalGuards,
      };
}

@immutable
class OmniShellConfigVmSection {
  final int workerThreads;
  final int simdArenaCapacity;

  const OmniShellConfigVmSection({
    this.workerThreads = 4,
    this.simdArenaCapacity = 4096,
  });

  Map<String, dynamic> toLegacyMap() => <String, dynamic>{
        'workerThreads': workerThreads,
        'simdArenaCapacity': simdArenaCapacity,
      };
}

@immutable
class OmniShellConfigTelemetrySection {
  final bool enabled;
  final bool frameMonitor;

  const OmniShellConfigTelemetrySection({
    this.enabled = true,
    this.frameMonitor = true,
  });

  Map<String, dynamic> toLegacyMap() => <String, dynamic>{
        'enabled': enabled,
        'frameMonitor': frameMonitor,
      };
}

@immutable
class OmniShellConfigAppSection {
  final String appName;
  final String title;
  final String locale;
  final String version;
  final OmniShellConfigThemeSection theme;
  final OmniShellConfigRouterSection router;
  final OmniShellConfigVmSection vm;
  final OmniShellConfigTelemetrySection telemetry;
  final List<Map<String, dynamic>> domains;
  final Map<String, dynamic> state;
  final Map<String, dynamic> macros;
  final Map<String, dynamic> schemas;
  final Map<String, dynamic> pipes;
  final Map<String, dynamic> actions;
  final Map<String, dynamic> sdui;
  final Map<String, dynamic>? boot;

  const OmniShellConfigAppSection({
    required this.appName,
    this.title = '',
    this.locale = 'en',
    this.version = '1.0.0',
    this.theme = const OmniShellConfigThemeSection(),
    this.router = const OmniShellConfigRouterSection(),
    this.vm = const OmniShellConfigVmSection(),
    this.telemetry = const OmniShellConfigTelemetrySection(),
    this.domains = const [],
    this.state = const {},
    this.macros = const {},
    this.schemas = const {},
    this.pipes = const {},
    this.actions = const {},
    this.sdui = const {},
    this.boot,
  });

  Map<String, dynamic> toLegacyMap() => <String, dynamic>{
        'app': <String, dynamic>{
          'name': appName,
          if (title.isNotEmpty) 'title': title,
          if (locale.isNotEmpty) 'locale': locale,
          if (version.isNotEmpty) 'version': version,
        },
        'theme': theme.toLegacyMap(),
        'router': router.toLegacyMap(),
        'vm': vm.toLegacyMap(),
        'telemetry': telemetry.toLegacyMap(),
        if (domains.isNotEmpty) 'domains': domains,
        if (state.isNotEmpty) 'state': state,
        if (macros.isNotEmpty) 'macros': macros,
        if (schemas.isNotEmpty) 'schemas': schemas,
        if (pipes.isNotEmpty) 'pipes': pipes,
        if (actions.isNotEmpty) 'actions': actions,
        if (sdui.isNotEmpty) 'sdui': sdui,
        if (boot != null) 'boot': boot,
      };
}

@immutable
class OmniShellConfigApiSection {
  final String apiUrl;
  final String socketUrl;
  final String cacheDirectoryPath;
  final String environment;
  final String? clientSecret;
  final bool enableTelemetry;
  final bool enableOfflineQueueing;
  final QuantumDriverMode driverMode;
  final Duration mockMinLatency;
  final Duration mockMaxLatency;
  final double mockFailureProbability;

  const OmniShellConfigApiSection({
    required this.apiUrl,
    required this.socketUrl,
    required this.cacheDirectoryPath,
    this.environment = 'production',
    this.clientSecret,
    this.enableTelemetry = true,
    this.enableOfflineQueueing = true,
    this.driverMode = QuantumDriverMode.http,
    this.mockMinLatency = const Duration(milliseconds: 1),
    this.mockMaxLatency = const Duration(milliseconds: 5),
    this.mockFailureProbability = 0.0,
  });

  Map<String, dynamic> toLegacyMap() => <String, dynamic>{
        'api': <String, dynamic>{
          'baseUrl': apiUrl,
          'socketUrl': socketUrl,
          'cacheDirectoryPath': cacheDirectoryPath,
          'environment': environment,
          if (clientSecret != null) 'clientSecret': clientSecret,
          'enableTelemetry': enableTelemetry,
          'enableOfflineQueueing': enableOfflineQueueing,
          'driverMode': driverMode.name,
          'mockMinLatencyMs': mockMinLatency.inMilliseconds,
          'mockMaxLatencyMs': mockMaxLatency.inMilliseconds,
          'mockFailureProbability': mockFailureProbability,
        },
      };
}

@immutable
class OmniShellConfigRemoteSourceSpec {
  final List<OmniShellConfigSource> sources;
  final bool enableRemote;
  final bool allowFallbackToLocal;
  final Duration timeout;

  const OmniShellConfigRemoteSourceSpec({
    this.sources = const [],
    this.enableRemote = true,
    this.allowFallbackToLocal = true,
    this.timeout = const Duration(seconds: 10),
  });
}

@immutable
class OmniShellConfigLocalSourceSpec {
  final List<OmniShellConfigSource> sources;

  const OmniShellConfigLocalSourceSpec({
    this.sources = const [],
  });
}

@immutable
class OmniShellConfigSources {
  final OmniShellConfigLocalSourceSpec local;
  final OmniShellConfigRemoteSourceSpec remote;

  const OmniShellConfigSources({
    this.local = const OmniShellConfigLocalSourceSpec(),
    this.remote = const OmniShellConfigRemoteSourceSpec(),
  });

  List<OmniShellConfigSource> orderedSources() {
    final list = <OmniShellConfigSource>[
      ...local.sources.where((s) => s.enabled),
      if (remote.enableRemote) ...remote.sources.where((s) => s.enabled),
    ];
    list.sort((a, b) => a.priority.compareTo(b.priority));
    return List<OmniShellConfigSource>.unmodifiable(list);
  }
}

@immutable
class OmniShellConfigRoot {
  final OmniShellConfigAppSection app;
  final OmniShellConfigApiSection api;
  final OmniShellConfigSecurityPolicy security;
  final OmniShellConfigMergePolicy merge;
  final OmniShellConfigCachePolicy cache;
  final OmniShellConfigSources sources;
  final Map<String, dynamic> extras;
  final QuantumBuildOverlay buildOverlay;

  const OmniShellConfigRoot({
    required this.app,
    required this.api,
    this.security = const OmniShellConfigSecurityPolicy(),
    this.merge = const OmniShellConfigMergePolicy(),
    this.cache = const OmniShellConfigCachePolicy(),
    this.sources = const OmniShellConfigSources(),
    this.extras = const {},
    this.buildOverlay = const QuantumBuildOverlay(
      data: <String, dynamic>{},
      lockedPaths: <String>{},
    ),
  });

  OmniShellConfigRoot withBuildOverlay(QuantumBuildOverlay overlay) {
    return OmniShellConfigRoot(
      app: app,
      api: api,
      security: security,
      merge: merge,
      cache: cache,
      sources: sources,
      extras: extras,
      buildOverlay: overlay,
    );
  }

  OmniShellConfigRoot withExtras(Map<String, dynamic> newExtras) {
    return OmniShellConfigRoot(
      app: app,
      api: api,
      security: security,
      merge: merge,
      cache: cache,
      sources: sources,
      extras: newExtras,
      buildOverlay: buildOverlay,
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Resolution snapshot
// ────────────────────────────────────────────────────────────────────────────

@immutable
class OmniShellConfigResolutionReport {
  final List<String> sourceOrder;
  final Map<String, String> sourceHashes;
  final List<String> skippedLockedPaths;
  final List<String> sensitivePaths;
  final Duration elapsed;
  final bool usedCache;

  const OmniShellConfigResolutionReport({
    required this.sourceOrder,
    required this.sourceHashes,
    required this.skippedLockedPaths,
    required this.sensitivePaths,
    required this.elapsed,
    required this.usedCache,
  });

  OmniShellConfigResolutionReport copyWith({
    List<String>? sourceOrder,
    Map<String, String>? sourceHashes,
    List<String>? skippedLockedPaths,
    List<String>? sensitivePaths,
    Duration? elapsed,
    bool? usedCache,
  }) {
    return OmniShellConfigResolutionReport(
      sourceOrder: sourceOrder ?? this.sourceOrder,
      sourceHashes: sourceHashes ?? this.sourceHashes,
      skippedLockedPaths: skippedLockedPaths ?? this.skippedLockedPaths,
      sensitivePaths: sensitivePaths ?? this.sensitivePaths,
      elapsed: elapsed ?? this.elapsed,
      usedCache: usedCache ?? this.usedCache,
    );
  }
}

@immutable
class QuantumResolvedConfig {
  final OmniShellConfigRoot blueprint;
  final Map<String, dynamic> raw;
  final OmniShellConfigResolutionReport report;

  const QuantumResolvedConfig({
    required this.blueprint,
    required this.raw,
    required this.report,
  });

  Map<String, dynamic> get legacyYamlMap =>
      Map<String, dynamic>.unmodifiable(raw);

  QLAppYamlConfig toYamlConfig() => QLAppYamlConfig.fromMap(raw);

  Future<QuantumAppManifest> toManifest({
    List<QLRoute> routes = const [],
    QuantumProductionRegistry? registry,
    QuantumRuntimeServices services = const QuantumRuntimeServices(),
    Widget? notFoundWidget,
    Future<void> Function()? onBoot,
    Future<void> Function(BuildContext context)? onReady,
  }) async {
    final config = toYamlConfig();
    final boot = raw['boot'] is Map
        ? QuantumBootSchema.fromMap(
            Map<String, dynamic>.from(raw['boot'] as Map),
            appName: config.appName,
          )
        : QuantumBootSchema(
            appName: config.appName,
            pagesDir: config.pagesDir,
          );

    final fileRoutes = routes.isNotEmpty
        ? routes
        : await QuantumFileRouter.instance.buildRoutes(
            config.pagesDir,
          );

    return QuantumAppManifest.fromYamlConfig(
      config,
      routes: fileRoutes,
      registry: registry,
      services: services,
      notFoundWidget: notFoundWidget,
      onBoot: onBoot,
      onReady: onReady,
      boot: boot,
    );
  }

  Map<String, dynamic> toApiBootstrapMap() {
    final apiSection = raw['api'] is Map
        ? Map<String, dynamic>.from(raw['api'] as Map)
        : <String, dynamic>{};

    final runtimeSection = raw['runtime'] is Map
        ? Map<String, dynamic>.from(raw['runtime'] as Map)
        : <String, dynamic>{};

    return Map<String, dynamic>.unmodifiable({
      'apiUrl': apiSection['baseUrl'] ?? blueprint.api.apiUrl,
      'socketUrl': apiSection['socketUrl'] ?? blueprint.api.socketUrl,
      'cacheDirectoryPath':
          apiSection['cacheDirectoryPath'] ?? blueprint.api.cacheDirectoryPath,
      'environment': apiSection['environment'] ?? blueprint.api.environment,
      'clientSecret': apiSection['clientSecret'] ?? blueprint.api.clientSecret,
      'enableTelemetry':
          apiSection['enableTelemetry'] ?? blueprint.api.enableTelemetry,
      'enableOfflineQueueing': apiSection['enableOfflineQueueing'] ??
          blueprint.api.enableOfflineQueueing,
      'driverMode': apiSection['driverMode'] ?? blueprint.api.driverMode.name,
      'mockMinLatencyMs': apiSection['mockMinLatencyMs'] ??
          blueprint.api.mockMinLatency.inMilliseconds,
      'mockMaxLatencyMs': apiSection['mockMaxLatencyMs'] ??
          blueprint.api.mockMaxLatency.inMilliseconds,
      'mockFailureProbability': apiSection['mockFailureProbability'] ??
          blueprint.api.mockFailureProbability,
      if (runtimeSection.isNotEmpty) 'runtime': runtimeSection,
    });
  }

  OmniShellConfig toQuantumRuntimeConfig() {
    final map = toApiBootstrapMap();
    final driverName = map['driverMode']?.toString().toLowerCase() ?? 'http';
    final driverMode = QuantumDriverMode.values.firstWhere(
      (m) => m.name == driverName,
      orElse: () => blueprint.api.driverMode,
    );

    return OmniShellConfig(
      apiUrl: map['apiUrl']?.toString() ?? '',
      socketUrl: map['socketUrl']?.toString() ?? '',
      cacheDirectoryPath: map['cacheDirectoryPath']?.toString() ?? '',
      environment: map['environment']?.toString() ?? 'production',
      clientSecret: map['clientSecret']?.toString(),
      enableTelemetry: map['enableTelemetry'] as bool? ?? true,
      enableOfflineQueueing: map['enableOfflineQueueing'] as bool? ?? true,
      driverMode: driverMode,
    );
  }

  bool get hasLockedSensitiveFields =>
      blueprint.security.requireBuildLockForSensitive &&
      blueprint.security.sensitivePaths.isNotEmpty;
}

// ────────────────────────────────────────────────────────────────────────────
// Resolver
// ────────────────────────────────────────────────────────────────────────────

class OmniShellConfigException implements Exception {
  final String message;
  final String? sourceId;
  final Map<String, dynamic> details;

  const OmniShellConfigException(
    this.message, {
    this.sourceId,
    this.details = const {},
  });

  @override
  String toString() {
    final id = sourceId == null ? '' : ' [$sourceId]';
    return 'OmniShellConfigException$id: $message';
  }
}

class OmniShellConfigResolver {
  final OmniShellConfigRoot blueprint;
  final OmniShellConfigSourceContext context;

  final Map<String, QuantumResolvedConfig> _memo =
      <String, QuantumResolvedConfig>{};
  final Map<String, DateTime> _memoAt = <String, DateTime>{};
  final Map<String, Future<QuantumResolvedConfig>> _inFlight =
      <String, Future<QuantumResolvedConfig>>{};

  OmniShellConfigResolver(
    this.blueprint, {
    OmniShellConfigSourceContext? context,
    QuantumHttpTransport? http,
    Map<String, String>? env,
    SecureStorageDelegate? secureVault, // <-- CHANGED HERE
    bool useCache = true,
  }) : context = context ??
            OmniShellConfigSourceContext(
              yaml: QuantumYamlEngine.instance,
              http: http ?? QuantumHttpTransport.platform(),
              env: env ?? const {},
              secureVault: secureVault,
              useCache: useCache,
            );

  Future<QuantumResolvedConfig> resolve({bool forceRefresh = false}) {
    final memoKey = _memoKey();
    final now = DateTime.now();
    final ttl = blueprint.sources.remote.enableRemote &&
            blueprint.sources.remote.sources.isNotEmpty
        ? blueprint.cache.remoteTtl
        : blueprint.cache.localTtl;

    if (!forceRefresh &&
        blueprint.cache.enableMemoization &&
        _memo.containsKey(memoKey)) {
      final age = now.difference(_memoAt[memoKey] ?? now);
      if (age <= ttl) {
        final cached = _memo[memoKey]!;
        return Future<QuantumResolvedConfig>.value(
          QuantumResolvedConfig(
            blueprint: cached.blueprint,
            raw: cached.raw,
            report: cached.report.copyWith(usedCache: true),
          ),
        );
      }
      _memo.remove(memoKey);
      _memoAt.remove(memoKey);
    }

    if (blueprint.cache.singleFlight && _inFlight.containsKey(memoKey)) {
      return _inFlight[memoKey]!;
    }

    final future = _resolveInternal(forceRefresh: forceRefresh).then((value) {
      if (blueprint.cache.enableMemoization) {
        _memo[memoKey] = value;
        _memoAt[memoKey] = DateTime.now();
        _pruneMemo();
      }
      return value;
    });

    if (blueprint.cache.singleFlight) {
      _inFlight[memoKey] = future;
    }

    return future.whenComplete(() {
      _inFlight.remove(memoKey);
    });
  }

  Future<QuantumResolvedConfig> _resolveInternal(
      {required bool forceRefresh}) async {
    final stopwatch = Stopwatch()..start();

    final buildOverlay = blueprint.buildOverlay.data.isNotEmpty
        ? blueprint.buildOverlay
        : QuantumBuildOverlay.fromEnv();

    final merged = <String, dynamic>{};
    final skipped = <String>[];
    final hashes = <String, String>{};
    final order = <String>[];
    final sensitive = <String>[];

    // Base build-time layer first.
    _deepOverlay(
      merged,
      buildOverlay.data,
      blueprint.merge,
      blueprint.security.copyWithLocked(buildOverlay.lockedPaths),
      path: '',
      skippedLockedPaths: skipped,
      sensitivePaths: sensitive,
    );

    // Legacy app/api defaults.
    _deepOverlay(
      merged,
      blueprint.app.toLegacyMap(),
      blueprint.merge,
      blueprint.security.copyWithLocked(buildOverlay.lockedPaths),
      path: '',
      skippedLockedPaths: skipped,
      sensitivePaths: sensitive,
    );
    _deepOverlay(
      merged,
      blueprint.api.toLegacyMap(),
      blueprint.merge,
      blueprint.security.copyWithLocked(buildOverlay.lockedPaths),
      path: '',
      skippedLockedPaths: skipped,
      sensitivePaths: sensitive,
    );

    // Extras are applied before file sources, so sources can override them
    // unless locked. This is useful for framework defaults.
    if (blueprint.extras.isNotEmpty) {
      _deepOverlay(
        merged,
        blueprint.extras,
        blueprint.merge,
        blueprint.security.copyWithLocked(buildOverlay.lockedPaths),
        path: '',
        skippedLockedPaths: skipped,
        sensitivePaths: sensitive,
      );
    }

    final sourceList = blueprint.sources.orderedSources();
    for (final source in sourceList) {
      order.add(source.stableKey);
      final result = await source.load(context);
      hashes[source.stableKey] = result.contentHash;
      _deepOverlay(
        merged,
        result.data,
        blueprint.merge,
        blueprint.security.copyWithLocked(buildOverlay.lockedPaths),
        path: '',
        skippedLockedPaths: skipped,
        sensitivePaths: sensitive,
      );
    }

    final report = OmniShellConfigResolutionReport(
      sourceOrder: List<String>.unmodifiable(order),
      sourceHashes: Map<String, String>.unmodifiable(hashes),
      skippedLockedPaths: List<String>.unmodifiable(skipped),
      sensitivePaths: List<String>.unmodifiable(sensitive),
      elapsed: stopwatch.elapsed,
      usedCache: false,
    );

    final resolved = QuantumResolvedConfig(
      blueprint: blueprint,
      raw: Map<String, dynamic>.unmodifiable(merged),
      report: report,
    );

    return resolved;
  }

  void _pruneMemo() {
    if (blueprint.cache.maxSnapshots <= 0) return;
    if (_memo.length <= blueprint.cache.maxSnapshots) return;
    final keys = _memo.keys.toList(growable: false);
    for (var i = 0; i < _memo.length - blueprint.cache.maxSnapshots; i++) {
      _memo.remove(keys[i]);
    }
  }

  String _memoKey() {
    final rootHash = _sha256OfMap({
      'app': blueprint.app.toLegacyMap(),
      'api': blueprint.api.toLegacyMap(),
      'security': {
        'lockedPaths': blueprint.security.lockedPaths.toList()..sort(),
        'sensitivePaths': blueprint.security.sensitivePaths.toList()..sort(),
        'requireBuildLockForSensitive':
            blueprint.security.requireBuildLockForSensitive,
        'requireSignedRemoteConfig':
            blueprint.security.requireSignedRemoteConfig,
      },
      'merge': {
        'listMode': blueprint.merge.listMode.name,
        'deepMergeMaps': blueprint.merge.deepMergeMaps,
        'mergeNulls': blueprint.merge.mergeNulls,
        'allowNewKeys': blueprint.merge.allowNewKeys,
        'preferRemoteOnConflict': blueprint.merge.preferRemoteOnConflict,
      },
      'sources':
          blueprint.sources.orderedSources().map((s) => s.stableKey).toList(),
    });
    return rootHash;
  }
}

extension on OmniShellConfigSecurityPolicy {
  OmniShellConfigSecurityPolicy copyWithLocked(Set<String> locked) {
    return OmniShellConfigSecurityPolicy(
      lockedPaths: <String>{...lockedPaths, ...locked},
      sensitivePaths: sensitivePaths,
      requireBuildLockForSensitive: requireBuildLockForSensitive,
      requireSignedRemoteConfig: requireSignedRemoteConfig,
      allowUnsignedRemoteConfigInDebug: allowUnsignedRemoteConfigInDebug,
      persistEncryptedRemoteCache: persistEncryptedRemoteCache,
      cacheSensitiveValuesInVault: cacheSensitiveValuesInVault,
      vaultNamespace: vaultNamespace,
      remoteSignatureKeyEnv: remoteSignatureKeyEnv,
      remoteEncryptionKeyEnv: remoteEncryptionKeyEnv,
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Helpers
// ────────────────────────────────────────────────────────────────────────────

void _deepOverlay(
  Map<String, dynamic> target,
  Map<String, dynamic> overlay,
  OmniShellConfigMergePolicy merge,
  OmniShellConfigSecurityPolicy security, {
  required String path,
  required List<String> skippedLockedPaths,
  required List<String> sensitivePaths,
}) {
  overlay.forEach((key, value) {
    final fullPath = path.isEmpty ? key : '$path.$key';

    if (security.isLocked(fullPath)) {
      skippedLockedPaths.add(fullPath);
      return;
    }

    if (security.isSensitive(fullPath)) {
      sensitivePaths.add(fullPath);
    }

    final current = target[key];
    if (value == null && !merge.mergeNulls) {
      return;
    }

    if (merge.deepMergeMaps &&
        value is Map &&
        current is Map &&
        _isMapLike(current)) {
      final next = <String, dynamic>{..._normalizeMap(current as Map)};
      _deepOverlay(
        next,
        _normalizeMap(value),
        merge,
        security,
        path: fullPath,
        skippedLockedPaths: skippedLockedPaths,
        sensitivePaths: sensitivePaths,
      );
      target[key] = next;
      return;
    }

    if (value is List && current is List) {
      switch (merge.listMode) {
        case OmniShellConfigListMergeMode.replace:
          target[key] = List<dynamic>.unmodifiable(value);
          return;
        case OmniShellConfigListMergeMode.concat:
          target[key] = List<dynamic>.unmodifiable(<dynamic>[
            ...current,
            ...value,
          ]);
          return;
        case OmniShellConfigListMergeMode.uniqueConcat:
          final seen = <String>{};
          final out = <dynamic>[];
          for (final item in current) {
            final token = _stableToken(item);
            if (seen.add(token)) out.add(item);
          }
          for (final item in value) {
            final token = _stableToken(item);
            if (seen.add(token)) out.add(item);
          }
          target[key] = List<dynamic>.unmodifiable(out);
          return;
      }
    }

    if (!merge.allowNewKeys && !target.containsKey(key)) {
      return;
    }

    target[key] = value;
  });
}

bool _isMapLike(dynamic value) => value is Map;

Map<String, dynamic> _normalizeMap(Map value) {
  final out = <String, dynamic>{};
  value.forEach((key, val) {
    out[key.toString()] = _normalizeDynamic(val);
  });
  return out;
}

dynamic _normalizeDynamic(dynamic value) {
  if (value is Map) return _normalizeMap(value);
  if (value is List)
    return value.map(_normalizeDynamic).toList(growable: false);
  return value;
}

String _stableToken(dynamic value) {
  if (value is Map || value is List) {
    return _sha256OfString(jsonEncode(_normalizeDynamic(value)));
  }
  return value.toString();
}

String _sha256OfString(String input) =>
    sha256.convert(utf8.encode(input)).toString();

String _sha256OfMap(Map<String, dynamic> map) {
  return _sha256OfString(jsonEncode(_canonicalize(map)));
}

Object _canonicalize(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((e) => e.toString()).toList()..sort();
    return <String, dynamic>{
      for (final key in keys) key: _canonicalize(value[key]),
    };
  }
  if (value is List) {
    return value.map(_canonicalize).toList(growable: false);
  }
  return value ?? '';
}
