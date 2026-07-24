import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:path_provider_windows/path_provider_windows.dart';
import 'package:quantum_layout/quantum.dart';
import 'package:quantum_layout/src/runtime/quantum_embodiment_examples.dart';

void main() {
  setUpAll(() async {
    // Initialize FFI for SQLite in tests
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Register dummy path provider for sqflite test
    PathProviderPlatform.instance = PathProviderWindows();

    // Initialize the VM singleton
    TestWidgetsFlutterBinding.ensureInitialized();
    QuantumVM.instance.initialize();

    // Register test schemas
    QEEExamples.registerAll();

    // Configure QEE with memory SQLite DB for testing
    await QEmbodiment.configure(const QEEConfig(
      dbPath: inMemoryDatabasePath,
      captureTelemetry: false,
      captureMemory: false,
      verboseLog: false,
    ));
  });

  test('Run all QEE Examples (Self-Asserting Scenarios)', () async {
    final traces = await QEEExamples.runAll(stopOnFirstFailure: false);

    bool allPassed = true;
    for (final trace in traces) {
      final isIntentionalFailure =
          trace.name == 'policy: counter zero triggers warn' ||
              trace.name == 'scenario: multi-step with rollback';

      if (trace.summary?.allPassed != true && !isIntentionalFailure) {
        allPassed = false;
        print('FAILED SCENARIO: ${trace.name}');
        for (final step in trace.steps) {
          if (!step.passed) {
            print('  Failed step: ${step.label}');
            for (final r in step.assertions.records.where((r) => !r.passed)) {
              print('    -> ${r.label}: ${r.detail}');
            }
          }
        }
      }
    }

    expect(allPassed, isTrue,
        reason: 'One or more QEE Example Scenarios failed');
  });
}
