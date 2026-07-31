// ════════════════════════════════════════════════════════════════════════════
// quantum.config.dart.example
//
// Copy this file to `quantum.config.dart` and edit the single source of truth.
// The actual implementation lives in `quantum.config.dart`.
// This template shows the intended developer-facing shape with stronger defaults.
// ════════════════════════════════════════════════════════════════════════════

import 'package:quantum_layout/quantum.dart';
import 'package:quantum_layout/src/runtime/api/network_shell.dart';

// ────────────────────────────────────────────────────────────────────────────
// Example starter object
// ────────────────────────────────────────────────────────────────────────────

final OmniShellConfigRoot quantumConfig = OmniShellConfigRoot(
  app: OmniShellConfigAppSection(
    appName: 'OmniShellApp',
    title: '',
    locale: 'en',
    version: '1.0.0',
    theme: OmniShellConfigThemeSection(
      mode: 'system',
      colors: <String, dynamic>{},
      typography: <String, dynamic>{},
      spacing: <String, dynamic>{},
      breakpoints: <String, dynamic>{},
      shadows: <String, dynamic>{},
      radii: <String, dynamic>{},
    ),
    router: OmniShellConfigRouterSection(
      initialRoute: '/',
      pagesDir: 'pages',
      notFoundPage: null,
      globalGuards: <Map<String, dynamic>>[],
    ),
    vm: OmniShellConfigVmSection(
      workerThreads: 4,
      simdArenaCapacity: 4096,
    ),
    telemetry: OmniShellConfigTelemetrySection(
      enabled: true,
      frameMonitor: true,
    ),
    domains: <Map<String, dynamic>>[],
    state: <String, dynamic>{},
    macros: <String, dynamic>{},
    schemas: <String, dynamic>{},
    pipes: <String, dynamic>{},
    actions: <String, dynamic>{},
    sdui: <String, dynamic>{},
    boot: <String, dynamic>{
      'appName': 'OmniShellApp',
      'pagesDir': 'pages',
    },
  ),
  api: OmniShellConfigApiSection(
    apiUrl: '',
    socketUrl: '',
    cacheDirectoryPath: '',
    environment: 'production',
    clientSecret: null,
    enableTelemetry: true,
    enableOfflineQueueing: true,
    driverMode: QuantumDriverMode.http,
    mockMinLatency: Duration(milliseconds: 1),
    mockMaxLatency: Duration(milliseconds: 5),
    mockFailureProbability: 0.0,
  ),
  security: OmniShellConfigSecurityPolicy(
    lockedPaths: <String>{
      'api.clientSecret',
    },
    sensitivePaths: <String>{
      'api.clientSecret',
      'security.clientSecret',
    },
    requireBuildLockForSensitive: true,
    requireSignedRemoteConfig: false,
    allowUnsignedRemoteConfigInDebug: true,
    persistEncryptedRemoteCache: true,
    cacheSensitiveValuesInVault: true,
  ),
  merge: OmniShellConfigMergePolicy(
    listMode: OmniShellConfigListMergeMode.replace,
    deepMergeMaps: true,
    mergeNulls: false,
    allowNewKeys: true,
    preferRemoteOnConflict: true,
  ),
  cache: OmniShellConfigCachePolicy(
    enableMemoization: true,
    remoteTtl: Duration(minutes: 5),
    localTtl: Duration(days: 3650),
    maxSnapshots: 4,
    singleFlight: true,
    useSourceDigests: true,
  ),
  sources: OmniShellConfigSources(
    local: OmniShellConfigLocalSourceSpec(
      sources: <OmniShellConfigSource>[
        QuantumAssetConfigSource(
          id: 'app-yaml',
          assetPath: 'APP.yaml',
          priority: 10,
        ),
      ],
    ),
    // remote: OmniShellConfigRemoteSourceSpec(
    //   sources: <OmniShellConfigSource>[
    //     OmniShellHttpConfigSource(
    //       id: 'remote-config',
    //       uri: Uri.parse('https://example.invalid/quantum-config.yaml'),
    //       priority: 100,
    //       timeout: Duration(seconds: 10),
    //       cacheByEtag: true,
    //     ),
    //   ],
    // ),
  ),
  extras: <String, dynamic>{},
  buildOverlay: QuantumBuildOverlay(
    data: <String, dynamic>{},
    lockedPaths: <String>{},
  ),
);
