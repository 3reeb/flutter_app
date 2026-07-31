// ════════════════════════════════════════════════════════════════════════════
// quantum_app_boot.dart
//
// Recommended public boot surface for developers.
// This file keeps startup simple while reusing the existing manifest/runtime
// implementation from quantum_app_entry.dart and quantum_app_shell.dart.
// ════════════════════════════════════════════════════════════════════════════

library quantum_app_boot;

import 'package:flutter/material.dart';

import '../../quantum.dart';
import 'quantum_app_entry.dart'
    show
        QLYamlAppEnv,
        QuantumAppManifest,
        bootQuantumApp,
        bootQuantumManifestApp,
        bootQuantumYamlApp,
        quantumApp;
import 'quantum_app_shell.dart'
    show
        QuantumAppConfig,
        QuantumProductionRegistry,
        QuantumRouterConfig,
        QuantumRuntimeServices,
        QuantumTelemetryConfig,
        QuantumVMConfig;
import 'quantum_boot_schema.dart';

export 'quantum_app_entry.dart'
    show
        QLYamlAppEnv,
        QuantumAppManifest,
        bootQuantumApp,
        bootQuantumManifestApp,
        bootQuantumYamlApp,
        quantumApp;
export 'quantum_app_shell.dart'
    show
        QuantumAppConfig,
        QuantumProductionRegistry,
        QuantumRouterConfig,
        QuantumRuntimeServices,
        QuantumTelemetryConfig,
        QuantumVMConfig;

/// A tiny, explicit wrapper around the manifest-based boot flow.
///
/// Use this in new apps when you want one obvious place to start from.
@immutable
class QuantumAppBootstrap {
  final QuantumAppManifest manifest;

  const QuantumAppBootstrap(this.manifest);

  QuantumAppBootstrap.quick({
    required String appName,
    String? title,
    ThemeMode themeMode = ThemeMode.system,
    ThemeData? lightTheme,
    ThemeData? darkTheme,
    List<QuantumDomain> domains = const [],
    QuantumRouterConfig router = const QuantumRouterConfig(),
    QuantumTelemetryConfig telemetry = const QuantumTelemetryConfig(),
    QuantumVMConfig vm = const QuantumVMConfig(),
    QuantumBootSchema? boot,
    QuantumProductionRegistry? registry,
    QuantumRuntimeServices services = const QuantumRuntimeServices(),
    Future<void> Function()? onBoot,
    Future<void> Function(BuildContext context)? onReady,
    Map<String, dynamic> raw = const {},
  }) : manifest = quantumApp(
          appName: appName,
          title: title,
          themeMode: themeMode,
          lightTheme: lightTheme,
          darkTheme: darkTheme,
          domains: domains,
          router: router,
          telemetry: telemetry,
          vm: vm,
          boot: boot,
          registry: registry,
          services: services,
          onBoot: onBoot,
          onReady: onReady,
          raw: raw,
        );

  QuantumAppConfig toConfig() => manifest.toAppConfig();

  void run() => bootQuantumManifestApp(manifest);
}

/// Convenience helper for the shortest possible app startup.
///
/// Example:
///
/// ```dart
/// void main() {
///   QuantumAppBootstrap.quick(appName: 'MyApp').run();
/// }
/// ```
QuantumAppBootstrap quantumAppBoot({
  required String appName,
  String? title,
  ThemeMode themeMode = ThemeMode.system,
  ThemeData? lightTheme,
  ThemeData? darkTheme,
  List<QuantumDomain> domains = const [],
  QuantumRouterConfig router = const QuantumRouterConfig(),
  QuantumTelemetryConfig telemetry = const QuantumTelemetryConfig(),
  QuantumVMConfig vm = const QuantumVMConfig(),
  QuantumBootSchema? boot,
  QuantumProductionRegistry? registry,
  QuantumRuntimeServices services = const QuantumRuntimeServices(),
  Future<void> Function()? onBoot,
  Future<void> Function(BuildContext context)? onReady,
  Map<String, dynamic> raw = const {},
}) {
  return QuantumAppBootstrap.quick(
    appName: appName,
    title: title,
    themeMode: themeMode,
    lightTheme: lightTheme,
    darkTheme: darkTheme,
    domains: domains,
    router: router,
    telemetry: telemetry,
    vm: vm,
    boot: boot,
    registry: registry,
    services: services,
    onBoot: onBoot,
    onReady: onReady,
    raw: raw,
  );
}

/// Alias for the legacy YAML bootstrap environment.
typedef QuantumAppYamlEnv = QLYamlAppEnv;
