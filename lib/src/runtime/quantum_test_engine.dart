// ════════════════════════════════════════════════════════════════════════════
// QUANTUM TEST ENGINE — facade
// src/runtime/quantum_test_engine.dart
// ════════════════════════════════════════════════════════════════════════════

library quantum_test_engine;

export 'quantum_test_engine_shared.dart';
export 'quantum_test_engine_stub.dart'
    if (dart.library.io) 'quantum_test_engine_io.dart';
