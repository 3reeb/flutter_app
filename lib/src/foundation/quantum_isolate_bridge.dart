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
