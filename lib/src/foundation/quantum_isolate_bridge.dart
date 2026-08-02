/*
 * ============================================================================
 * File: quantum_isolate_bridge.dart
 * 
 * Description:
 * Cross-Platform Isolate Safety Wrapper. Provides a unified API for spawning 
 * background computations that safely degrades to synchronous execution on platforms 
 * lacking isolate support (e.g., Flutter Web).
 * 
 * Key Components:
 * - QLIsolateBridge: Manages safe execution and data transfer across isolate boundaries.
 * 
 * Dependencies/Relationships:
 * Utilized by heavy parsing tasks like quantum_yaml_engine.dart and large JSON 
 * payload decoding.
 * 
 * Notes:
 * Protects the UI thread from dropping frames during heavy computation. Always use 
 * this bridge instead of raw Isolate.run() for cross-platform compatibility.
 * Created At: 2026-08-02T07:37:47+03:00
 * ============================================================================
 */
import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
/// Shared isolate helper used by API, auth, media, and socket layers.
///
/// The same `Isolate.run` fallback had been duplicated across multiple files.
/// Keeping it here makes the hot-path code smaller and easier to audit.
abstract final class QLIsolateBridge {
  static const bool isWeb = kIsWeb;

  static Future<T> safeRun<T>(FutureOr<T> Function() computation) async {
    if (kIsWeb) return await computation();
    try {
      return await Isolate.run(computation);
    } on UnsupportedError {
      return await computation();
    }
  }
}
