import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quantum_layout/quantum.dart';

// Assuming quantum_file_router is available via package import
// We'll import it relative if necessary based on your folder structure.
import 'src/app/quantum_file_router.dart';

void main() async {
  // 1. Ensure Flutter bindings are ready for async asset loading
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Discover all assets dynamically
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);

  // 3. Build routes recursively from assets/pages/
  final routes = await QuantumFileRouter.instance.buildRoutesFromManifest(
    manifest,
    pagesDir: 'assets/pages', // Pointing to the generated pages folder
  );

  debugPrint('[SDUI Boot] Loaded ${routes.length} dynamic routes.');

  // 4. Boot the Quantum Engine
  bootQuantumApp(
    QuantumAppConfig(
      appName: 'Quantum Omega App',
      themeMode: ThemeMode.system,
      telemetry: const QuantumTelemetryConfig(
        enabled: true,
        enableFrameMonitorInDebug: true,
      ),
      vm: const QuantumVMConfig(workerThreads: 4, simdArenaCapacity: 16384),
      onBoot: () async {
        // 5. Load Kernel Configuration
        try {
          final kernelString = await rootBundle.loadString('assets/config/kernel.json');
          final kernelMap = jsonDecode(kernelString) as Map<String, dynamic>;

          // Apply global templates
          if (kernelMap['templates'] is Map) {
            (kernelMap['templates'] as Map).forEach((k, v) {
              if (v is Map) {
                QJsonTemplateEngine_D.define({'name': k, ...v});
              }
            });
            debugPrint('[SDUI Boot] Loaded ${kernelMap['templates'].length} templates.');
          }

          // Apply global macros
          if (kernelMap['macros'] is Map) {
            (kernelMap['macros'] as Map).forEach((k, v) {
              if (v is Map) {
                QJsonTemplateEngine_D.define({'name': k, ...v});
              }
            });
            debugPrint('[SDUI Boot] Loaded ${kernelMap['macros'].length} macros.');
          }

          // Apply global state / stores
          if (kernelMap['stores'] is Map) {
            (kernelMap['stores'] as Map).forEach((storeName, storeData) {
              if (storeData is Map) {
                QLStoreRegistry.instance
                    .get(storeName.toString())
                    .merge(storeData);
              }
            });
            debugPrint('[SDUI Boot] Initialized ${kernelMap['stores'].length} stores.');
          }

          // Apply schemas
          if (kernelMap['schemas'] is Map) {
            (kernelMap['schemas'] as Map).forEach((schemaName, schemaData) {
              if (schemaData is Map) {
                QLSchemaRegistry.instance.registerRaw(
                  schemaName.toString(), 
                  Map<String, dynamic>.from(schemaData)
                );
              }
            });
            debugPrint('[SDUI Boot] Registered ${kernelMap['schemas'].length} schemas.');
          }

        } catch (e, st) {
          debugPrint('[SDUI Boot Error] Failed to load kernel.json: $e\n$st');
        }
      },
      domains: [
        QuantumDomain(
          name: 'app_domain',
          routes: routes,
        ),
      ],
    ),
  );
}
