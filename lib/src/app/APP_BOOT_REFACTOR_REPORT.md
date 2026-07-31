# App Boot Refactor Report

The app layer now has a cleaner public startup surface:

- `quantum_app_boot.dart` is the recommended import for new apps.
- `quantum_app_entry.dart` remains available for the legacy/feature-rich boot path.
- `quantum_app_shell.dart` remains the runtime shell layer.
- `config.dart` now depends on the boot facade instead of the navigation engine import.

Recommended first app pattern:

```dart
import 'package:flutter/material.dart';
import 'src/app/quantum_app_boot.dart';

void main() {
  quantumAppBoot(
    appName: 'MyApp',
    title: 'My App',
  ).run();
}
```

Why this helps:

- one obvious startup entry point for developers
- lower coupling between boot and runtime layers
- easier to extend later without changing app startup code
- removes the direct app-config dependency on the navigation engine import
