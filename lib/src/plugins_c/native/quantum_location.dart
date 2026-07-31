import 'package:flutter/foundation.dart';
import '../../platform/quantum_native_bridge.dart';
import '../../foundation/quantum_async.dart';
// ────────────────────────────────────────────────────────────────────────────
// PRACTICAL LOCATION MODELS
// ────────────────────────────────────────────────────────────────────────────

class LocationData {
  final double latitude;
  final double longitude;

  const LocationData({
    required this.latitude,
    required this.longitude,
  });

  factory LocationData.fromMap(Map<String, dynamic> map) {
    return LocationData(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// CODECS & BRIDGES
// ────────────────────────────────────────────────────────────────────────────

class _VoidLocationCodec extends QLChannelCodec<void, LocationData> {
  const _VoidLocationCodec();
  @override dynamic encode(void args) => null;
  @override LocationData decode(dynamic data) => LocationData.fromMap(Map<String, dynamic>.from(data));
}

class _CurrentLocationBridge extends QLMethodBridge<void, LocationData> {
  @override String get channelName => 'quantum_location/current';
  @override QLChannelCodec<void, LocationData> get codec => const _VoidLocationCodec();
}

class _LocationStreamBridge extends QLEventBridge<LocationData> {
  @override String get channelName => 'quantum_location/stream';
  @override QLChannelCodec<void, LocationData> get codec => const _VoidLocationCodec();
}

// ────────────────────────────────────────────────────────────────────────────
// PRACTICAL API FACADE
// ────────────────────────────────────────────────────────────────────────────

class QuantumLocation {
  static final QuantumLocation instance = QuantumLocation._();

  QuantumLocation._() {
    QLNativeBridgeRegistry.instance.register('quantum_location/current', _current);
    QLNativeBridgeRegistry.instance.register('quantum_location/stream', _stream);
  }

  final _current = _CurrentLocationBridge();
  final _stream = _LocationStreamBridge();

  /// Gets the user's current GPS coordinate (useful for finding nearby stores or delivery drops).
  QLAsyncSignal<LocationData> getCurrentLocation() {
    return _current(null);
  }

  /// Streams live location updates (useful for real-time delivery tracking maps).
  QLAsyncSignal<LocationData> listenLocationUpdates() {
    return _stream.stream();
  }
}
