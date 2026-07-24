import 'package:flutter/foundation.dart';
import '../../platform/quantum_native_bridge.dart';
import '../../foundation/quantum_async.dart';

// ────────────────────────────────────────────────────────────────────────────
// PRACTICAL PHOTOS MODELS
// ────────────────────────────────────────────────────────────────────────────

class MediaFile {
  final String path;
  final String mimeType;
  final int sizeBytes;

  const MediaFile({
    required this.path,
    required this.mimeType,
    required this.sizeBytes,
  });

  factory MediaFile.fromMap(Map<String, dynamic> map) {
    return MediaFile(
      path: map['path'] as String,
      mimeType: map['mimeType'] as String? ?? 'image/jpeg',
      sizeBytes: map['sizeBytes'] as int? ?? 0,
    );
  }
}

class PickerConfig {
  final bool allowMultiple;
  final bool allowVideos;

  const PickerConfig({
    this.allowMultiple = false,
    this.allowVideos = false,
  });

  Map<String, dynamic> toMap() => {
        'allowMultiple': allowMultiple,
        'allowVideos': allowVideos,
      };
}

// ────────────────────────────────────────────────────────────────────────────
// CODECS & BRIDGES
// ────────────────────────────────────────────────────────────────────────────

class _PickerCodec extends QLChannelCodec<PickerConfig, List<MediaFile>> {
  const _PickerCodec();
  @override dynamic encode(PickerConfig args) => args.toMap();
  @override List<MediaFile> decode(dynamic data) {
    if (data == null) return [];
    return (data as List).map((e) => MediaFile.fromMap(Map<String, dynamic>.from(e))).toList();
  }
}

class _PickMediaBridge extends QLMethodBridge<PickerConfig, List<MediaFile>> {
  @override String get channelName => 'quantum_photos/pick';
  @override QLChannelCodec<PickerConfig, List<MediaFile>> get codec => const _PickerCodec();
}

// ────────────────────────────────────────────────────────────────────────────
// PRACTICAL API FACADE
// ────────────────────────────────────────────────────────────────────────────

class QuantumPhotos {
  static final QuantumPhotos instance = QuantumPhotos._();

  QuantumPhotos._() {
    QLNativeBridgeRegistry.instance.register('quantum_photos/pick', _pick);
  }

  final _pick = _PickMediaBridge();

  /// Opens the native photo picker to select images/videos (useful for profile pics or chat media sharing).
  QLAsyncSignal<List<MediaFile>> pickMedia({PickerConfig config = const PickerConfig()}) {
    return _pick(config);
  }
}
