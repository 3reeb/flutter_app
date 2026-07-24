import 'package:flutter/foundation.dart';
import '../../platform/quantum_native_bridge.dart';
import '../../foundation/quantum_async.dart';

// ────────────────────────────────────────────────────────────────────────────
// PRACTICAL MICROPHONE MODELS
// ────────────────────────────────────────────────────────────────────────────

class AudioRecordingResult {
  final String path;
  final int durationSeconds;

  const AudioRecordingResult({
    required this.path,
    required this.durationSeconds,
  });

  factory AudioRecordingResult.fromMap(Map<String, dynamic> map) {
    return AudioRecordingResult(
      path: map['path'] as String,
      durationSeconds: map['durationSeconds'] as int? ?? 0,
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// CODECS & BRIDGES
// ────────────────────────────────────────────────────────────────────────────

class _VoidBoolCodec extends QLChannelCodec<void, bool> {
  const _VoidBoolCodec();
  @override dynamic encode(void args) => null;
  @override bool decode(dynamic data) => data == true;
}

class _ResultCodec extends QLChannelCodec<void, AudioRecordingResult> {
  const _ResultCodec();
  @override dynamic encode(void args) => null;
  @override AudioRecordingResult decode(dynamic data) => AudioRecordingResult.fromMap(Map<String, dynamic>.from(data));
}

class _StartBridge extends QLMethodBridge<void, bool> {
  @override String get channelName => 'quantum_microphone/start';
  @override QLChannelCodec<void, bool> get codec => const _VoidBoolCodec();
}

class _StopBridge extends QLMethodBridge<void, AudioRecordingResult> {
  @override String get channelName => 'quantum_microphone/stop';
  @override QLChannelCodec<void, AudioRecordingResult> get codec => const _ResultCodec();
}

class _AmplitudeStreamBridge extends QLEventBridge<double> {
  @override String get channelName => 'quantum_microphone/amplitude';
  @override QLChannelCodec<void, double> get codec => const _VoidDoubleCodec();
}

class _VoidDoubleCodec extends QLChannelCodec<void, double> {
  const _VoidDoubleCodec();
  @override dynamic encode(void args) => null;
  @override double decode(dynamic data) => (data as num).toDouble();
}

// ────────────────────────────────────────────────────────────────────────────
// PRACTICAL API FACADE
// ────────────────────────────────────────────────────────────────────────────

class QuantumMicrophone {
  static final QuantumMicrophone instance = QuantumMicrophone._();

  QuantumMicrophone._() {
    QLNativeBridgeRegistry.instance.register('quantum_microphone/start', _start);
    QLNativeBridgeRegistry.instance.register('quantum_microphone/stop', _stop);
    QLNativeBridgeRegistry.instance.register('quantum_microphone/amplitude', _amplitude);
  }

  final _start = _StartBridge();
  final _stop = _StopBridge();
  final _amplitude = _AmplitudeStreamBridge();

  /// Starts recording audio (perfect for Voice Notes in chat apps).
  QLAsyncSignal<bool> startRecording() {
    return _start(null);
  }

  /// Stops recording and returns the path to the saved audio file.
  QLAsyncSignal<AudioRecordingResult> stopRecording() {
    return _stop(null);
  }

  /// Stream of audio amplitude (0.0 to 1.0) to build UI waveforms while recording.
  QLAsyncSignal<double> listenAmplitude() {
    return _amplitude.stream();
  }
}
