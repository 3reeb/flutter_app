// ════════════════════════════════════════════════════════════════════════════
// quantum.config.dart.example
//
// Copy this file to `quantum.config.dart` and edit the single source of truth.
// The actual implementation lives in `quantum.config.dart`.
// This template shows the intended developer-facing shape with stronger defaults.
// ════════════════════════════════════════════════════════════════════════════

import 'package:quantum_layout/quantum.dart';
// ────────────────────────────────────────────────────────────────────────────
// Example starter object
// ────────────────────────────────────────────────────────────────────────────

final QuantumConfigRoot quantumConfig = QuantumConfigRoot(
  app: QuantumConfigAppSection(
    appName: 'QuantumApp',
    title: '',
    locale: 'en',
    version: '1.0.0',
    theme: QuantumConfigThemeSection(
      mode: 'system',
      colors: <String, dynamic>{},
      typography: <String, dynamic>{},
      spacing: <String, dynamic>{},
      breakpoints: <String, dynamic>{},
      shadows: <String, dynamic>{},
      radii: <String, dynamic>{},
    ),
    router: QuantumConfigRouterSection(
      initialRoute: '/',
      pagesDir: 'pages',
      notFoundPage: null,
      globalGuards: <Map<String, dynamic>>[],
    ),
    vm: QuantumConfigVmSection(
      workerThreads: 4,
      simdArenaCapacity: 4096,
    ),
    telemetry: QuantumConfigTelemetrySection(
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
      'appName': 'QuantumApp',
      'pagesDir': 'pages',
    },
  ),
  api: QuantumConfigApiSection(
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
  security: QuantumConfigSecurityPolicy(
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
  merge: QuantumConfigMergePolicy(
    listMode: QuantumConfigListMergeMode.replace,
    deepMergeMaps: true,
    mergeNulls: false,
    allowNewKeys: true,
    preferRemoteOnConflict: true,
  ),
  cache: QuantumConfigCachePolicy(
    enableMemoization: true,
    remoteTtl: Duration(minutes: 5),
    localTtl: Duration(days: 3650),
    maxSnapshots: 4,
    singleFlight: true,
    useSourceDigests: true,
  ),
  sources: QuantumConfigSources(
    local: QuantumConfigLocalSourceSpec(
      sources: <QuantumConfigSource>[
        QuantumAssetConfigSource(
          id: 'app-yaml',
          assetPath: 'APP.yaml',
          priority: 10,
        ),
      ],
    ),
    // remote: QuantumConfigRemoteSourceSpec(
    //   sources: <QuantumConfigSource>[
    //     QuantumHttpConfigSource(
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
