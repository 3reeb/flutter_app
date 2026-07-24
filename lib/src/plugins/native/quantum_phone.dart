import 'package:flutter/foundation.dart';
import '../../platform/quantum_native_bridge.dart';
import '../../foundation/quantum_async.dart';

// ────────────────────────────────────────────────────────────────────────────
// PRACTICAL PHONE MODELS
// ────────────────────────────────────────────────────────────────────────────

// No complex models needed for opening the dialer

// ────────────────────────────────────────────────────────────────────────────
// CODECS & BRIDGES
// ────────────────────────────────────────────────────────────────────────────

class _DialBridge extends QLMethodBridge<String, bool> {
  @override String get channelName => 'quantum_phone/dial';
  @override QLChannelCodec<String, bool> get codec => const _StringBoolCodec();
}

class _StringBoolCodec extends QLChannelCodec<String, bool> {
  const _StringBoolCodec();
  @override dynamic encode(String args) => args;
  @override bool decode(dynamic data) => data == true;
}

// ────────────────────────────────────────────────────────────────────────────
// PRACTICAL API FACADE
// ────────────────────────────────────────────────────────────────────────────

class QuantumPhone {
  static final QuantumPhone instance = QuantumPhone._();

  QuantumPhone._() {
    QLNativeBridgeRegistry.instance.register('quantum_phone/dial', _dial);
  }

  final _dial = _DialBridge();

  /// Opens the native phone dialer pre-filled with the number (useful for "Call Support" or "Call Driver" buttons).
  /// This avoids needing the dangerous CALL_PHONE permission which often gets apps rejected.
  QLAsyncSignal<bool> openDialer(String number) {
    return _dial(number);
  }
}
