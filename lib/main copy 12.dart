import 'package:flutter/material.dart';
import 'package:quantum_layout/quantum.dart';
import 'package:quantum_layout/src/app/config.dart';
import 'quantum.config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Resolve the OmniShellConfigRoot which will now fetch the 'assets/config/kernel.json'
  // as a data source and merge it into the config blueprint.
  final resolved = await OmniShellConfigResolver(quantumConfig).resolve();

  // Convert the resolved configuration into a QuantumAppManifest
  final manifest = await resolved.toManifest();

  // Boot the app using the manifest
  bootQuantumManifestApp(manifest);
}
