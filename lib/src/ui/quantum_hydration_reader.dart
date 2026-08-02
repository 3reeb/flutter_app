/*
 * ============================================================================
 * File: quantum_hydration_reader.dart
 * 
 * Description:
 * Platform-conditional exported reader for Quantum hydration properties, routing to either HTML or stub implementations.
 * 
 * Key Components:
 * - readQuantumHydrationProps: Universal entrypoint for reading DOM properties.
 * 
 * Dependencies/Relationships:
 * Routes to quantum_hydration_reader_stub.dart (Native) or quantum_hydration_reader_html.dart (Web).
 * 
 * Notes:
 * Standard conditional export pattern.
 * ============================================================================
 */
import 'quantum_hydration_reader_stub.dart'
    if (dart.library.html) 'quantum_hydration_reader_html.dart';

Map<String, dynamic>? readQuantumHydrationProps() => quantumReadDomProps();
