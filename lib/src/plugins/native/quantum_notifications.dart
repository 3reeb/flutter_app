import 'package:flutter/foundation.dart';
import '../../platform/quantum_native_bridge.dart';
import '../../foundation/quantum_async.dart';

// ────────────────────────────────────────────────────────────────────────────
// PRACTICAL NOTIFICATIONS MODELS
// ────────────────────────────────────────────────────────────────────────────

class SimpleNotification {
  final int id;
  final String title;
  final String body;
  final String payload; // Data attached to handle when tapped

  const SimpleNotification({
    required this.id,
    required this.title,
    required this.body,
    this.payload = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'body': body,
        'payload': payload,
      };
}

class NotificationTap {
  final int id;
  final String payload;

  const NotificationTap({
    required this.id,
    required this.payload,
  });

  factory NotificationTap.fromMap(Map<String, dynamic> map) {
    return NotificationTap(
      id: map['id'] as int,
      payload: map['payload'] as String? ?? '',
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// CODECS & BRIDGES
// ────────────────────────────────────────────────────────────────────────────

class _ShowCodec extends QLChannelCodec<SimpleNotification, bool> {
  const _ShowCodec();
  @override dynamic encode(SimpleNotification args) => args.toMap();
  @override bool decode(dynamic data) => data == true;
}

class _ShowBridge extends QLMethodBridge<SimpleNotification, bool> {
  @override String get channelName => 'quantum_notifications/show';
  @override QLChannelCodec<SimpleNotification, bool> get codec => const _ShowCodec();
}

class _CancelBridge extends QLMethodBridge<int, bool> {
  @override String get channelName => 'quantum_notifications/cancel';
  @override QLChannelCodec<int, bool> get codec => const _IntBoolCodec();
}

class _IntBoolCodec extends QLChannelCodec<int, bool> {
  const _IntBoolCodec();
  @override dynamic encode(int args) => args;
  @override bool decode(dynamic data) => data == true;
}

class _TapStreamBridge extends QLEventBridge<NotificationTap> {
  @override String get channelName => 'quantum_notifications/taps';
  @override QLChannelCodec<void, NotificationTap> get codec => QLMapCodec<NotificationTap>((map) => NotificationTap.fromMap(map));
}

// ────────────────────────────────────────────────────────────────────────────
// PRACTICAL API FACADE
// ────────────────────────────────────────────────────────────────────────────

class QuantumNotifications {
  static final QuantumNotifications instance = QuantumNotifications._();

  QuantumNotifications._() {
    QLNativeBridgeRegistry.instance.register('quantum_notifications/show', _show);
    QLNativeBridgeRegistry.instance.register('quantum_notifications/cancel', _cancel);
    QLNativeBridgeRegistry.instance.register('quantum_notifications/taps', _taps);
  }

  final _show = _ShowBridge();
  final _cancel = _CancelBridge();
  final _taps = _TapStreamBridge();

  /// Shows a standard local notification (useful for background chat messages).
  QLAsyncSignal<bool> show(SimpleNotification notification) {
    return _show(notification);
  }

  /// Cancels an active notification by ID.
  QLAsyncSignal<bool> cancel(int id) {
    return _cancel(id);
  }

  /// Stream of user taps on notifications so the app can route to the correct screen via payload.
  QLAsyncSignal<NotificationTap> listenForTaps() {
    return _taps.stream();
  }
}
