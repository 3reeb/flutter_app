import 'package:flutter/foundation.dart';
import '../../platform/quantum_native_bridge.dart';
import '../../foundation/quantum_async.dart';
// ────────────────────────────────────────────────────────────────────────────
// PRACTICAL CAMERA MODELS
// ────────────────────────────────────────────────────────────────────────────

enum CameraLens { front, back }

enum FlashMode { off, auto, on }

class CameraConfig {
  final CameraLens lens;
  final FlashMode flashMode;
  final bool enableAudio;

  const CameraConfig({
    this.lens = CameraLens.back,
    this.flashMode = FlashMode.auto,
    this.enableAudio = true,
  });

  Map<String, dynamic> toMap() => {
        'lens': lens.name,
        'flashMode': flashMode.name,
        'enableAudio': enableAudio,
      };
}

class MediaResult {
  final String path;
  final int sizeBytes;

  const MediaResult({
    required this.path,
    required this.sizeBytes,
  });

  factory MediaResult.fromMap(Map<String, dynamic> map) {
    return MediaResult(
      path: map['path'] as String,
      sizeBytes: map['sizeBytes'] as int? ?? 0,
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// CODECS & BRIDGES
// ────────────────────────────────────────────────────────────────────────────

class _InitCodec extends QLChannelCodec<CameraConfig, bool> {
  const _InitCodec();
  @override
  dynamic encode(CameraConfig args) => args.toMap();
  @override
  bool decode(dynamic data) => data == true;
}

class _MediaCodec extends QLChannelCodec<void, MediaResult> {
  const _MediaCodec();
  @override
  dynamic encode(void args) => null;
  @override
  MediaResult decode(dynamic data) =>
      MediaResult.fromMap(Map<String, dynamic>.from(data));
}

class _InitBridge extends QLMethodBridge<CameraConfig, bool> {
  @override
  String get channelName => 'quantum_camera/init';
  @override
  QLChannelCodec<CameraConfig, bool> get codec => const _InitCodec();
}

// class _DisposeBridge extends QLMethodBridge<void, bool> {
//   @override String get channelName => 'quantum_camera/dispose';
//   @override QLChannelCodec<void, bool> get codec => const QLChannelCodec<void, bool>.from(
//       encode: (void args) => null, decode: (dynamic data) => data == true) as QLChannelCodec<void, bool>;
// }

class _VoidBoolCodec extends QLChannelCodec<void, bool> {
  const _VoidBoolCodec();
  @override
  dynamic encode(void args) => null;
  @override
  bool decode(dynamic data) => data == true;
}

class _DisposeBridgeImpl extends QLMethodBridge<void, bool> {
  @override
  String get channelName => 'quantum_camera/dispose';
  @override
  QLChannelCodec<void, bool> get codec => const _VoidBoolCodec();
}

class _TakePhotoBridge extends QLMethodBridge<void, MediaResult> {
  @override
  String get channelName => 'quantum_camera/take_photo';
  @override
  QLChannelCodec<void, MediaResult> get codec => const _MediaCodec();
}

class _StartVideoBridge extends QLMethodBridge<void, bool> {
  @override
  String get channelName => 'quantum_camera/start_video';
  @override
  QLChannelCodec<void, bool> get codec => const _VoidBoolCodec();
}

class _StopVideoBridge extends QLMethodBridge<void, MediaResult> {
  @override
  String get channelName => 'quantum_camera/stop_video';
  @override
  QLChannelCodec<void, MediaResult> get codec => const _MediaCodec();
}

// ────────────────────────────────────────────────────────────────────────────
// PRACTICAL API FACADE
// // ────────────────────────────────────────────────────────────────────────────

// class QuantumCamera {
//   static final QuantumCamera instance = QuantumCamera._();

//   QuantumCamera._() {
//     QLNativeBridgeRegistry.instance.register('quantum_camera/init', _init);
//     QLNativeBridgeRegistry.instance.register('quantum_camera/dispose', _dispose);
//     QLNativeBridgeRegistry.instance.register('quantum_camera/take_photo', _takePhoto);
//     QLNativeBridgeRegistry.instance.register('quantum_camera/start_video', _startVideo);
//     QLNativeBridgeRegistry.instance.register('quantum_camera/stop_video', _stopVideo);
//   }

//   final _init = _InitBridge();
//   final _dispose = _DisposeBridgeImpl();
//   final _takePhoto = _TakePhotoBridge();
//   final _startVideo = _StartVideoBridge();
//   final _stopVideo = _StopVideoBridge();

//   /// Initializes the camera view.
//   QLAsyncSignal<bool> initialize({CameraConfig config = const CameraConfig()}) {
//     return _init(config);
//   }

//   /// Disposes the camera and releases resources.
//   QLAsyncSignal<bool> dispose() => _dispose(null);

//   /// Takes a photo and saves it to a temporary file, returning the path.
//   QLAsyncSignal<MediaResult> takePhoto() => _takePhoto(null);

//   /// Starts recording a video.
//   QLAsyncSignal<bool> startVideoRecording() => _startVideo(null);

//   /// Stops recording and returns the video file path.
//   QLAsyncSignal<MediaResult> stopVideoRecording() => _stopVideo(null);
// }
