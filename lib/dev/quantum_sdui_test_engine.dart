
// ════════════════════════════════════════════════════════════════════════════
// QUANTUM SDUI TEST ENGINE — facade export
// quantum_sdui_test_engine.dart
//
// Use `QuantumSduiTestEngine.instance` to discover folder-based JSON cases,
// compile them, render them in a hidden probe, and detect blank frames.
// ════════════════════════════════════════════════════════════════════════════

export 'quantum_sdui_test_engine_shared.dart';
export 'quantum_sdui_test_engine_stub.dart'
    if (dart.library.io) 'quantum_sdui_test_engine_io.dart';
