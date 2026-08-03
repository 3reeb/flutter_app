// =============================================================================
// media.dart — Media: tracks, manifests, adaptive sessions, UDP, JitterBuffer.
// =============================================================================

import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'types.dart';

// ---------------------------------------------------------------------------
// UdpMediaPacket — binary packet: [seq:2][ts:4][type:1][payload…]
// ---------------------------------------------------------------------------

class UdpMediaPacket {
  final int sequence;
  final int timestamp;
  final UdpPacketType type;
  final Uint8List payload;

  const UdpMediaPacket({
    required this.sequence,
    required this.timestamp,
    required this.type,
    required this.payload,
  });

  Uint8List toBytes() {
    final bytes = Uint8List(7 + payload.length);
    final bd = ByteData.sublistView(bytes);
    bd.setUint16(0, sequence, Endian.big);
    bd.setUint32(2, timestamp, Endian.big);
    bd.setUint8(6, type.index);
    bytes.setAll(7, payload);
    return bytes;
  }

  factory UdpMediaPacket.fromBytes(Uint8List bytes) {
    if (bytes.length < 7) throw Exception('Packet undersized (${bytes.length}B)');
    final bd = ByteData.sublistView(bytes);
    final ti = bd.getUint8(6).clamp(0, UdpPacketType.values.length - 1);
    return UdpMediaPacket(
      sequence: bd.getUint16(0, Endian.big),
      timestamp: bd.getUint32(2, Endian.big),
      type: UdpPacketType.values[ti],
      payload: Uint8List.sublistView(bytes, 7),
    );
  }
}

// ---------------------------------------------------------------------------
// UdpConnection (abstract)
// ---------------------------------------------------------------------------

abstract class UdpConnection {
  Stream<UdpMediaPacket> get frames;
  Future<void> send(UdpMediaPacket packet);
  Future<void> close();
}

// ---------------------------------------------------------------------------
// JitterBuffer — O(1) reorder with forced flush after maxDelayMs
// ---------------------------------------------------------------------------

class JitterBuffer {
  final int maxDelayMs;
  final Map<int, UdpMediaPacket> _buffer = {};
  final Queue<int> _emittedQueue = ListQueue<int>();
  final HashSet<int> _emittedSet = HashSet<int>();
  final StreamController<UdpMediaPacket> _ordered =
      StreamController<UdpMediaPacket>.broadcast();

  int _expectedSeq = -1;
  Timer? _forceTimer;
  bool _flushScheduled = false;

  JitterBuffer({this.maxDelayMs = 150});

  Stream<UdpMediaPacket> get orderedFrames => _ordered.stream;

  void insert(UdpMediaPacket packet) {
    if (_emittedSet.contains(packet.sequence) ||
        _buffer.containsKey(packet.sequence)) return;
    if (_expectedSeq == -1) {
      _expectedSeq = packet.sequence;
    } else {
      final dist = (packet.sequence - _expectedSeq) & 0xffff;
      if (dist > 32767) _expectedSeq = packet.sequence;
    }
    _buffer[packet.sequence] = packet;
    _forceTimer?.cancel();
    _forceTimer =
        Timer(Duration(milliseconds: maxDelayMs), () => _flush(true));
    _scheduleFlush();
  }

  void _scheduleFlush() {
    if (_flushScheduled) return;
    _flushScheduled = true;
    scheduleMicrotask(() {
      _flushScheduled = false;
      _flush(false);
    });
  }

  void _flush(bool forced) {
    while (_buffer.containsKey(_expectedSeq)) {
      final p = _buffer.remove(_expectedSeq)!;
      _emittedQueue.add(p.sequence);
      _emittedSet.add(p.sequence);
      if (_emittedQueue.length > 10000) {
        _emittedSet.remove(_emittedQueue.removeFirst());
      }
      if (!_ordered.isClosed) _ordered.add(p);
      _expectedSeq = (_expectedSeq + 1) & 0xffff;
    }
    if (forced && _buffer.isNotEmpty) {
      final sorted = _buffer.keys.toList()
        ..sort((a, b) {
          final d = (a - b) & 0xffff;
          return d > 32767 ? -1 : 1;
        });
      _expectedSeq = sorted.first;
      _flush(false);
    }
  }

  void dispose() {
    _forceTimer?.cancel();
    _buffer.clear();
    _emittedQueue.clear();
    _emittedSet.clear();
    if (!_ordered.isClosed) _ordered.close();
  }
}

// ---------------------------------------------------------------------------
// MediaTrack / MediaManifest
// ---------------------------------------------------------------------------

class MediaTrack {
  final String id;
  final MediaTrackType type;
  final int bitrate;
  final int? width;
  final int? height;
  final Uri uri;
  final Map<String, dynamic> meta;

  const MediaTrack({
    required this.id,
    required this.type,
    required this.bitrate,
    required this.uri,
    this.width,
    this.height,
    this.meta = const {},
  });

  factory MediaTrack.fromJson(dynamic json) {
    final m = (json as Map).cast<String, dynamic>();
    return MediaTrack(
      id: m['id']?.toString() ?? '',
      type: MediaTrackType.values.firstWhere(
        (e) => e.name == (m['type']?.toString() ?? 'video'),
        orElse: () => MediaTrackType.video,
      ),
      bitrate: (m['bitrate'] as num?)?.toInt() ?? 0,
      uri: Uri.parse(m['uri']?.toString() ?? ''),
      width: (m['width'] as num?)?.toInt(),
      height: (m['height'] as num?)?.toInt(),
      meta: Map<String, dynamic>.from(m['meta'] ?? const {}),
    );
  }
}

class MediaManifest {
  final String mediaId;
  final List<MediaTrack> tracks;
  final MediaTrack? defaultTrack;
  final Map<String, dynamic> meta;

  const MediaManifest({
    required this.mediaId,
    required this.tracks,
    this.defaultTrack,
    this.meta = const {},
  });

  factory MediaManifest.fromJson(dynamic json) {
    final m = (json as Map).cast<String, dynamic>();
    final tracks =
        (m['tracks'] as List? ?? const []).map(MediaTrack.fromJson).toList();
    return MediaManifest(
      mediaId: m['mediaId']?.toString() ?? '',
      tracks: tracks,
      defaultTrack: m['defaultTrack'] == null
          ? null
          : MediaTrack.fromJson(m['defaultTrack']),
      meta: Map<String, dynamic>.from(m['meta'] ?? const {}),
    );
  }
}

// ---------------------------------------------------------------------------
// AdaptiveMediaSession / MediaPlaybackSession
// ---------------------------------------------------------------------------

class MediaSwitchEvent {
  final MediaTrack? oldTrack;
  final MediaTrack newTrack;
  final MediaSwitchMode mode;
  MediaSwitchEvent(
      {required this.newTrack,
      this.oldTrack,
      this.mode = MediaSwitchMode.seamless});
}

class AdaptiveMediaSession {
  final String sessionId;
  final StreamController<MediaSwitchEvent> _switches =
      StreamController<MediaSwitchEvent>.broadcast();
  final StreamController<double> _buffer =
      StreamController<double>.broadcast();

  MediaManifest manifest;
  MediaTrack activeTrack;

  AdaptiveMediaSession(
      {required this.sessionId,
      required this.manifest,
      required this.activeTrack});

  Stream<MediaSwitchEvent> get switches => _switches.stream;
  Stream<double> get buffer => _buffer.stream;

  void updateBuffer(double v) {
    if (!_buffer.isClosed) _buffer.add(v.clamp(0.0, 1.0));
  }

  void switchTrack(MediaTrack next,
      {MediaSwitchMode mode = MediaSwitchMode.seamless}) {
    final old = activeTrack;
    activeTrack = next;
    if (!_switches.isClosed) {
      _switches.add(MediaSwitchEvent(oldTrack: old, newTrack: next, mode: mode));
    }
  }

  Future<void> dispose() async {
    await _switches.close();
    await _buffer.close();
  }
}

class MediaPlaybackSession {
  final AdaptiveMediaSession media;
  final StreamController<Duration> _position =
      StreamController<Duration>.broadcast();
  final StreamController<bool> _playing = StreamController<bool>.broadcast();

  bool _isPlaying = false;
  Duration _positionValue = Duration.zero;

  MediaPlaybackSession(this.media);

  Stream<Duration> get position => _position.stream;
  Stream<bool> get playing => _playing.stream;
  bool get isPlaying => _isPlaying;
  Duration get positionValue => _positionValue;

  void play() {
    _isPlaying = true;
    if (!_playing.isClosed) _playing.add(true);
  }

  void pause() {
    _isPlaying = false;
    if (!_playing.isClosed) _playing.add(false);
  }

  void seek(Duration v) {
    _positionValue = v;
    if (!_position.isClosed) _position.add(v);
  }

  void switchQuality(MediaTrack next) => media.switchTrack(next);

  Future<void> dispose() async {
    await _position.close();
    await _playing.close();
    await media.dispose();
  }
}
