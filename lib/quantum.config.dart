import 'package:quantum_layout/quantum.dart';
import 'package:quantum_layout/src/runtime/api/network_shell.dart';

// ────────────────────────────────────────────────────────────────────────────
// OmniShell Configuration
//
// This is the static baseline configuration for your app.
// Note: In this architecture, the actual pages, layouts, schemas, and global
// configs are driven entirely by `assets/config/kernel.json` and `assets/pages/`.
// ────────────────────────────────────────────────────────────────────────────

final OmniShellConfigRoot quantumConfig = OmniShellConfigRoot(
  app: OmniShellConfigAppSection(
    appName: 'OmniShell Omega SDUI',
    title: 'SDUI Application',
    locale: 'en',
    version: '1.0.0',
    theme: OmniShellConfigThemeSection(
      mode: 'system',
      colors: const <String, dynamic>{},
      typography: const <String, dynamic>{},
      spacing: const <String, dynamic>{},
      breakpoints: const <String, dynamic>{},
      shadows: const <String, dynamic>{},
      radii: const <String, dynamic>{},
    ),
    router: OmniShellConfigRouterSection(
      initialRoute: '/',
      pagesDir: 'assets/pages', // Point to our generated pages folder
      notFoundPage: null,
      globalGuards: const <Map<String, dynamic>>[],
    ),
    vm: OmniShellConfigVmSection(
      workerThreads: 4,
      simdArenaCapacity: 16384,
    ),
    telemetry: OmniShellConfigTelemetrySection(
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
      'appName': 'OmniShell Omega SDUI',
      'pagesDir': 'assets/pages',
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
  ),
  security: OmniShellConfigSecurityPolicy(
    lockedPaths: const <String>{},
    sensitivePaths: const <String>{},
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
    remoteTtl: const Duration(minutes: 5),
    localTtl: const Duration(days: 3650),
    maxSnapshots: 4,
    singleFlight: true,
    useSourceDigests: true,
  ),
  sources: OmniShellConfigSources(
    local: OmniShellConfigLocalSourceSpec(
      sources: const <OmniShellConfigSource>[
        QuantumAssetConfigSource(
          id: 'kernel',
          assetPath: 'assets/config/kernel.json',
        ),
      ],
    ),
  ),
  extras: const <String, dynamic>{},
  buildOverlay: QuantumBuildOverlay(
    data: const <String, dynamic>{},
    lockedPaths: const <String>{},
  ),
);
