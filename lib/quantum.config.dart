import 'package:quantum_layout/quantum.dart';

// ────────────────────────────────────────────────────────────────────────────
// Quantum Configuration
//
// This is the static baseline configuration for your app.
// Note: In this architecture, the actual pages, layouts, schemas, and global 
// configs are driven entirely by `assets/config/kernel.json` and `assets/pages/`.
// ────────────────────────────────────────────────────────────────────────────

final QuantumConfigRoot quantumConfig = QuantumConfigRoot(
  app: QuantumConfigAppSection(
    appName: 'Quantum Omega SDUI',
    title: 'SDUI Application',
    locale: 'en',
    version: '1.0.0',
    theme: QuantumConfigThemeSection(
      mode: 'system',
      colors: const <String, dynamic>{},
      typography: const <String, dynamic>{},
      spacing: const <String, dynamic>{},
      breakpoints: const <String, dynamic>{},
      shadows: const <String, dynamic>{},
      radii: const <String, dynamic>{},
    ),
    router: QuantumConfigRouterSection(
      initialRoute: '/',
      pagesDir: 'assets/pages', // Point to our generated pages folder
      notFoundPage: null,
      globalGuards: const <Map<String, dynamic>>[],
    ),
    vm: QuantumConfigVmSection(
      workerThreads: 4,
      simdArenaCapacity: 16384,
    ),
    telemetry: QuantumConfigTelemetrySection(
      enabled: true,
      frameMonitor: true,
    ),
    domains: const <Map<String, dynamic>>[],
    state: const <String, dynamic>{},
    macros: const <String, dynamic>{},
    schemas: const <String, dynamic>{},
    pipes: const <String, dynamic>{},
    actions: const <String, dynamic>{},
    sdui: const <String, dynamic>{},
    boot: const <String, dynamic>{
      'appName': 'Quantum Omega SDUI',
      'pagesDir': 'assets/pages',
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
    mockMinLatency: const Duration(milliseconds: 1),
    mockMaxLatency: const Duration(milliseconds: 5),
    mockFailureProbability: 0.0,
  ),
  security: QuantumConfigSecurityPolicy(
    lockedPaths: const <String>{},
    sensitivePaths: const <String>{},
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
    remoteTtl: const Duration(minutes: 5),
    localTtl: const Duration(days: 3650),
    maxSnapshots: 4,
    singleFlight: true,
    useSourceDigests: true,
  ),
  sources: QuantumConfigSources(
    local: QuantumConfigLocalSourceSpec(
      sources: const <QuantumConfigSource>[],
    ),
  ),
  extras: const <String, dynamic>{},
  buildOverlay: QuantumBuildOverlay(
    data: const <String, dynamic>{},
    lockedPaths: const <String>{},
  ),
);
