// ════════════════════════════════════════════════════════════════════════════
// QUANTUM NATIVE BRIDGE v1.0 - TYPE-SAFE PLATFORM CHANNEL LAYER
// quantum_native_bridge.dart
//
// ARCHITECTURE:
// 1. QLChannelCodec<TArgs, TResult>: Abstract typed encode/decode pair.
//    Eliminates all `dynamic` casts at the call site. The codec is the
//    single boundary between Dart type-safe code and platform raw maps.
// 2. QLNativeBridge<TArgs, TResult>: Abstract base that owns the channel
//    lifecycle. MethodChannel calls return QLAsyncSignal<TResult> — they
//    are auto-cancelled when the signal is disposed.
// 3. QLEventBridge<TResult>: EventChannel variant. Binds the platform
//    broadcast stream to a QLAsyncSignal, auto-cancels on dispose.
// 4. QLNativeBridgeRegistry: Singleton registry for named bridges.
//    Plugin system can look up bridges by channel name without DI containers.
// 5. QLBridgeScope: InheritedWidget to provide bridges to widget subtrees.
// 6. Zero-dynamic: Every raw `dynamic` from platform channels is immediately
//    decoded at the boundary via the codec. Internal code is fully typed.
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../foundation/quantum_async.dart';
import '../foundation/quantum_primitives.dart';

// ─────────────────────────────────────────────────────────────────────── §1 ─
//  TYPED CODEC (The Dynamic-to-Typed Firewall)
// ────────────────────────────────────────────────────────────────────────────

/// Defines the encode/decode contract for a specific platform channel.
/// TArgs: Dart type for method arguments (to platform).
/// TResult: Dart type for method result (from platform).
abstract class QLChannelCodec<TArgs, TResult> {
  const QLChannelCodec();

  /// Encodes Dart [args] into a platform-safe map/primitive.
  /// Return null for no-argument calls.
  dynamic encode(TArgs args);

  /// Decodes raw platform [data] into a typed [TResult].
  /// Throws [QLBridgeDecodeException] on malformed data.
  TResult decode(dynamic data);
}

/// A codec for no-argument, no-result channels.
class QLVoidCodec extends QLChannelCodec<void, void> {
  const QLVoidCodec();
  @override
  dynamic encode(void args) => null;
  @override
  void decode(dynamic data) => null;
}

/// A passthrough codec for String channels.
class QLStringCodec extends QLChannelCodec<String, String> {
  const QLStringCodec();
  @override
  dynamic encode(String args) => args;
  @override
  String decode(dynamic data) => data?.toString() ?? '';
}

/// A passthrough codec for typed Map channels.
class QLMapCodec<TResult>
    extends QLChannelCodec<Map<String, dynamic>, TResult> {
  final TResult Function(Map<String, dynamic>) _fromMap;
  final Map<String, dynamic> Function(Map<String, dynamic>)? _toMap;

  const QLMapCodec(this._fromMap, {Map<String, dynamic> Function(Map<String, dynamic>)? toMap})
      : _toMap = toMap;

  @override
  dynamic encode(Map<String, dynamic> args) => args;

  @override
  TResult decode(dynamic data) {
    if (data == null) throw const QLBridgeDecodeException('Null response from platform');
    if (data is! Map)
      throw QLBridgeDecodeException('Expected Map, got ${data.runtimeType}');
    return _fromMap(Map<String, dynamic>.from(data));
  }
}

// ─────────────────────────────────────────────────────────────────────── §2 ─
//  EXCEPTIONS
// ────────────────────────────────────────────────────────────────────────────

class QLBridgeDecodeException implements Exception {
  final String message;
  const QLBridgeDecodeException(this.message);
  @override
  String toString() => 'QLBridgeDecodeException: $message';
}

class QLBridgeInvokeException implements Exception {
  final String channelName;
  final String method;
  final Object cause;
  const QLBridgeInvokeException(this.channelName, this.method, this.cause);
  @override
  String toString() =>
      'QLBridgeInvokeException[$channelName/$method]: $cause';
}

// ─────────────────────────────────────────────────────────────────────── §3 ─
//  QLMETHODBRIDGE (MethodChannel — Request/Response)
// ────────────────────────────────────────────────────────────────────────────

/// A typed, lifecycle-bound MethodChannel wrapper.
/// Each [call] returns a fresh QLAsyncSignal<TResult> that:
///   - Starts loading immediately.
///   - Resolves with typed data on success.
///   - Resolves with typed error on PlatformException.
///   - Auto-cancels if the signal is disposed before platform responds.
abstract class QLMethodBridge<TArgs, TResult> {
  /// The Flutter channel name. Must match the platform-side channel name.
  String get channelName;

  /// The method to invoke. Override for multi-method channels.
  String get method => channelName;

  /// The codec handling encode/decode.
  QLChannelCodec<TArgs, TResult> get codec;

  late final MethodChannel _channel = MethodChannel(channelName);

  /// Invokes the platform method and returns a self-managing async signal.
  /// The signal is NOT stored by this bridge — caller owns its lifecycle.
  QLAsyncSignal<TResult> call(TArgs args) {
    final signal = QLAsyncSignal<TResult>();
    signal.load(() async {
      try {
        final dynamic raw = await _channel.invokeMethod<dynamic>(
          method,
          codec.encode(args),
        );
        return codec.decode(raw);
      } on PlatformException catch (e) {
        throw QLBridgeInvokeException(channelName, method, e);
      }
    });
    return signal;
  }

  /// Batched version: calls a list of arg sets, returns a list of signals.
  List<QLAsyncSignal<TResult>> callAll(List<TArgs> argsList) {
    return argsList.map(call).toList(growable: false);
  }
}

// ─────────────────────────────────────────────────────────────────────── §4 ─
//  QLEVENTBRIDGE (EventChannel — Streaming)
// ────────────────────────────────────────────────────────────────────────────

/// A typed, lifecycle-bound EventChannel wrapper.
/// [stream] returns a QLAsyncSignal<TResult> that:
///   - Binds to the platform EventChannel's broadcast stream.
///   - Decodes every platform event through the codec.
///   - Auto-cancels the StreamSubscription when the signal is disposed.
abstract class QLEventBridge<TResult> {
  String get channelName;
  QLChannelCodec<void, TResult> get codec;

  late final EventChannel _channel = EventChannel(channelName);

  /// Returns a lifecycle-bound signal streaming platform events.
  /// [arguments]: optional setup arguments sent to the platform side.
  QLAsyncSignal<TResult> stream({dynamic arguments}) {
    final signal = QLAsyncSignal<TResult>();
    final Stream<TResult> typedStream = _channel
        .receiveBroadcastStream(arguments)
        .map((dynamic event) => codec.decode(event));
    signal.bind(typedStream, cancelExisting: true);
    return signal;
  }
}

// ─────────────────────────────────────────────────────────────────────── §5 ─
//  QLBASICBRIDGE (BasicMessageChannel — Bidirectional)
// ────────────────────────────────────────────────────────────────────────────

/// A typed BasicMessageChannel wrapper for bidirectional messaging.
/// TArgs: message type to platform. TResult: message type from platform.
abstract class QLBasicBridge<TArgs, TResult> {
  String get channelName;
  QLChannelCodec<TArgs, TResult> get codec;
  MessageCodec<dynamic> get messageCodec => const JSONMessageCodec();

  BasicMessageChannel<dynamic>? _channel;

  BasicMessageChannel<dynamic> get _chan =>
      _channel ??= BasicMessageChannel<dynamic>(channelName, messageCodec);

  /// Sends a message to platform and returns the typed response.
  QLAsyncSignal<TResult> send(TArgs args) {
    final signal = QLAsyncSignal<TResult>();
    signal.load(() async {
      final dynamic raw = await _chan.send(codec.encode(args));
      return codec.decode(raw);
    });
    return signal;
  }

  /// Sets a handler for messages incoming FROM the platform.
  /// The handler receives typed [TResult] and can return typed [TArgs].
  void setMessageHandler(Future<TArgs?> Function(TResult message) handler) {
    _chan.setMessageHandler((dynamic message) async {
      final TResult typed = codec.decode(message);
      final TArgs? reply = await handler(typed);
      if (reply == null) return null;
      return codec.encode(reply);
    });
  }

  void clearMessageHandler() {
    _chan.setMessageHandler(null);
  }
}

// ─────────────────────────────────────────────────────────────────────── §6 ─
//  QLNATIVE BRIDGE REGISTRY (Global Channel Directory)
// ────────────────────────────────────────────────────────────────────────────

/// Global registry for all platform bridges.
/// Bridges register by channel name and can be resolved anywhere —
/// from SDUI action plugins, from DI-free code, from tests with mock bridges.
class QLNativeBridgeRegistry {
  static final QLNativeBridgeRegistry instance = QLNativeBridgeRegistry._();
  QLNativeBridgeRegistry._();

  final Map<String, Object> _bridges = {};

  /// Registers a bridge by its channel name. Safe to call multiple times
  /// with the same bridge instance (idempotent).
  void register(String channelName, Object bridge) {
    _bridges[channelName] = bridge;
  }

  /// Resolves a typed bridge by channel name.
  /// Returns null if not registered (avoids hard crashes in SDUI contexts).
  T? resolve<T>(String channelName) {
    final bridge = _bridges[channelName];
    if (bridge is T) return bridge;
    return null;
  }

  /// Resolves and immediately calls a QLMethodBridge.
  /// Convenience wrapper for SDUI action plugins.
  QLAsyncSignal<TResult>? invoke<TArgs, TResult>(
      String channelName, TArgs args) {
    final bridge = resolve<QLMethodBridge<TArgs, TResult>>(channelName);
    return bridge?.call(args);
  }

  /// Resolves and immediately streams a QLEventBridge.
  QLAsyncSignal<TResult>? listen<TResult>(String channelName,
      {dynamic arguments}) {
    final bridge = resolve<QLEventBridge<TResult>>(channelName);
    return bridge?.stream(arguments: arguments);
  }

  bool isRegistered(String channelName) => _bridges.containsKey(channelName);

  void unregister(String channelName) => _bridges.remove(channelName);

  void clear() => _bridges.clear();
}

// ─────────────────────────────────────────────────────────────────────── §7 ─
//  QLBRIDGE SCOPE (InheritedWidget Bridge Provider)
// ────────────────────────────────────────────────────────────────────────────

/// Provides typed bridge resolution to a widget subtree.
/// Wraps the global registry behind a BuildContext-accessible interface,
/// making it testable via mock registries in widget tests.
class QLBridgeScope extends InheritedWidget {
  final QLNativeBridgeRegistry registry;

  const QLBridgeScope({
    super.key,
    required this.registry,
    required super.child,
  });

  static QLNativeBridgeRegistry of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<QLBridgeScope>();
    return scope?.registry ?? QLNativeBridgeRegistry.instance;
  }

  @override
  bool updateShouldNotify(QLBridgeScope old) =>
      !identical(registry, old.registry);
}

// ─────────────────────────────────────────────────────────────────────── §8 ─
//  MOCK BRIDGE (Testing Infrastructure)
// ────────────────────────────────────────────────────────────────────────────

/// A fully in-memory MethodBridge for use in widget tests.
/// No MethodChannel is opened — responses are provided by the test.
class QLMockMethodBridge<TArgs, TResult>
    extends QLMethodBridge<TArgs, TResult> {
  @override
  final String channelName;
  @override
  final String method;
  @override
  final QLChannelCodec<TArgs, TResult> codec;

  final Future<TResult> Function(TArgs args) _handler;

  QLMockMethodBridge({
    required this.channelName,
    required this.codec,
    required Future<TResult> Function(TArgs args) handler,
    String? method,
  })  : method = method ?? channelName,
        _handler = handler;

  @override
  QLAsyncSignal<TResult> call(TArgs args) {
    final signal = QLAsyncSignal<TResult>();
    signal.load(() => _handler(args));
    return signal;
  }
}
