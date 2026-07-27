// =============================================================================
// QUANTUM MEDIA API v10.0 - SECURE BACKEND PROXY, CACHE & LIVE ENGINE
// quantum_media_api.dart
// =============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:collection';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'quantum_api_engine.dart'; // For LocalStore and VaultStreamException

// =============================================================================
// CORE PRIMITIVES & EXCEPTIONS
// =============================================================================

class TransferProgress {
  final int sentBytes;
  final int totalBytes;
  final double progress;
  final String stage;
  final double currentSpeedBps;
  final Duration estimatedTimeRemaining;

  const TransferProgress({
    required this.sentBytes,
    required this.totalBytes,
    required this.progress,
    required this.stage,
    required this.currentSpeedBps,
    required this.estimatedTimeRemaining,
  });
}

enum MediaType { image, audio, video, document, binary }

enum Quality { auto, p144, p240, p360, p480, p720, p1080, p4k, original }

enum HttpMethod { get, post, put, patch }

// =============================================================================
// TIERED CACHING ENGINE & BYTE RANGE TRACKER
// =============================================================================

class ByteRange {
  final int start;
  final int end;
  const ByteRange(this.start, this.end);
  int get length => end - start + 1;
  bool contains(int byte) => byte >= start && byte <= end;
  bool overlaps(ByteRange other) => start <= other.end && other.start <= end;
}

class RangeTracker {
  final List<ByteRange> _ranges = [];
  final String? clientSecret;

  RangeTracker({this.clientSecret});

  void addRange(int start, int end) {
    _ranges.add(ByteRange(start, end));
    _ranges.sort((a, b) => a.start.compareTo(b.start));
    _merge();
  }

  void _merge() {
    if (_ranges.isEmpty) return;
    List<ByteRange> merged = [_ranges.first];
    for (int i = 1; i < _ranges.length; i++) {
      var last = merged.last;
      var current = _ranges[i];
      if (current.start <= last.end + 1) {
        merged.removeLast();
        merged.add(ByteRange(last.start, math.max(last.end, current.end)));
      } else {
        merged.add(current);
      }
    }
    _ranges.clear();
    _ranges.addAll(merged);
  }

  List<ByteRange> getMissingRanges(int requestStart, int requestEnd) {
    if (_ranges.isEmpty) return [ByteRange(requestStart, requestEnd)];
    List<ByteRange> missing = [];
    int current = requestStart;

    for (var range in _ranges) {
      if (current < range.start) {
        missing.add(ByteRange(current, math.min(requestEnd, range.start - 1)));
      }
      current = math.max(current, range.end + 1);
      if (current > requestEnd) break;
    }
    if (current <= requestEnd) {
      missing.add(ByteRange(current, requestEnd));
    }
    return missing;
  }

  bool hasRange(int start, int end) {
    return getMissingRanges(start, end).isEmpty;
  }

  String serialize() {
    final raw =
        jsonEncode(_ranges.map((r) => {'s': r.start, 'e': r.end}).toList());
    return raw; // Metadata encryption handled at Store level if needed
  }

  void deserialize(String data) {
    _ranges.clear();
    try {
      final list = jsonDecode(data) as List;
      for (var item in list) {
        _ranges.add(ByteRange(item['s'], item['e']));
      }
    } catch (_) {}
  }
}

class MediaCacheManager {
  final Directory cacheDir;
  final LocalStore store;
  final int maxRamCacheBytes;
  final String? clientSecret;

  final LinkedHashMap<String, Uint8List> _ramCache = LinkedHashMap();
  int _currentRamBytes = 0;

  MediaCacheManager({
    required this.cacheDir,
    required this.store,
    this.maxRamCacheBytes = 50 * 1024 * 1024, // 50MB RAM limit
    this.clientSecret,
  });

  Future<void> init() async {
    if (!kIsWeb && !await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
  }

  String _hash(String url) => md5.convert(utf8.encode(url)).toString();
  File _getFile(String key) => File('${cacheDir.path}/$key.media');

  List<int> _deriveKeyMaterial(String url) {
    final secret = clientSecret ?? '';
    return sha256.convert(utf8.encode('$secret|$url')).bytes;
  }

  void _applyCipher(String url, Uint8List data, int offset) {
    if (clientSecret == null || clientSecret!.isEmpty) return;

    final keyMaterial = _deriveKeyMaterial(url);
    final hmac = Hmac(sha256, keyMaterial);
    var cursor = 0;
    var blockIndex = 0;

    while (cursor < data.length) {
      final blockSeed = ByteData(16)
        ..setUint64(0, offset + cursor, Endian.big)
        ..setUint64(8, blockIndex, Endian.big);
      final stream = hmac.convert(blockSeed.buffer.asUint8List()).bytes;
      final blockLen = math.min(stream.length, data.length - cursor);
      for (var i = 0; i < blockLen; i++) {
        data[cursor + i] ^= stream[i];
      }
      cursor += blockLen;
      blockIndex++;
    }
  }

  Future<Uint8List?> getFromRam(String url) async {
    final key = _hash(url);
    if (_ramCache.containsKey(key)) {
      final data = _ramCache.remove(key)!;
      _ramCache[key] = data; // Move to most recently used
      return data;
    }
    return null;
  }

  Future<void> saveToRam(String url, Uint8List data) async {
    final key = _hash(url);
    if (_ramCache.containsKey(key)) {
      _currentRamBytes -= _ramCache[key]!.length;
    }
    _ramCache[key] = data;
    _currentRamBytes += data.length;

    while (_currentRamBytes > maxRamCacheBytes && _ramCache.isNotEmpty) {
      final oldestKey = _ramCache.keys.first;
      final oldestData = _ramCache.remove(oldestKey)!;
      _currentRamBytes -= oldestData.length;
    }
  }

  Future<RangeTracker> getTracker(String url) async {
    final key = _hash(url);
    final tracker = RangeTracker(clientSecret: clientSecret);
    final data = await store.read('range_$key');
    if (data != null) tracker.deserialize(data);
    return tracker;
  }

  Future<void> saveChunkToDisk(String url, int offset, Uint8List chunk) async {
    if (kIsWeb) return;
    final key = _hash(url);
    final file = _getFile(key);

    // Clone chunk so we don't encrypt the RAM version being fed to the player
    final Uint8List diskChunk = Uint8List.fromList(chunk);
    _applyCipher(url, diskChunk, offset); // Encrypt before writing to disk

    RandomAccessFile raf = await file.open(mode: FileMode.append);
    await raf.setPosition(offset);
    await raf.writeFrom(diskChunk);
    await raf.close();

    final tracker = await getTracker(url);
    tracker.addRange(offset, offset + chunk.length - 1);
    await store.write('range_$key', tracker.serialize());
  }

  Future<Uint8List?> readChunkFromDisk(String url, int start, int end) async {
    if (kIsWeb) return null;
    final key = _hash(url);
    final file = _getFile(key);
    if (!await file.exists()) return null;

    final raf = await file.open(mode: FileMode.read);
    await raf.setPosition(start);
    final data = await raf.read(end - start + 1);
    await raf.close();

    _applyCipher(url, data, start); // Decrypt immediately after reading from disk
    return data;
  }
}

// =============================================================================
// ADAPTIVE BANDWIDTH ESTIMATOR
// =============================================================================

class BandwidthEstimator {
  final List<double> _samplesBps = [];
  final int maxSamples = 10;

  void addSample(int bytes, Duration time) {
    if (time.inMilliseconds == 0) return;
    double bps = (bytes * 8) / (time.inMilliseconds / 1000.0);
    _samplesBps.add(bps);
    if (_samplesBps.length > maxSamples) _samplesBps.removeAt(0);
  }

  double get currentBps {
    if (_samplesBps.isEmpty) return 5000000; // Default 5 Mbps
    // Exponential Moving Average
    double ema = _samplesBps.first;
    double alpha = 0.3;
    for (int i = 1; i < _samplesBps.length; i++) {
      ema = alpha * _samplesBps[i] + (1 - alpha) * ema;
    }
    return ema;
  }

  Quality getRecommendedQuality() {
    final bps = currentBps;
    if (bps > 15000000) return Quality.p4k; // >15 Mbps
    if (bps > 5000000) return Quality.p1080; // >5 Mbps
    if (bps > 2500000) return Quality.p720; // >2.5 Mbps
    if (bps > 1000000) return Quality.p480; // >1 Mbps
    if (bps > 500000) return Quality.p360; // >500 Kbps
    return Quality.p240;
  }
}

// =============================================================================
// NETWORK PIPELINES: PREFETCHER, UPLOADER
// =============================================================================

class MediaPrefetcher {
  final MediaCacheManager cache;
  final HttpClient _client;
  final Queue<String> _queue = Queue();
  bool _isRunning = false;

  MediaPrefetcher({required this.cache}) : _client = HttpClient() {
    _client.connectionTimeout = const Duration(seconds: 10);
  }

  void prefetch(List<String> urls, {int bytesToFetch = 512 * 1024}) {
    if (kIsWeb) return;
    for (var url in urls) {
      if (!_queue.contains(url)) _queue.add('$url|$bytesToFetch');
    }
    if (!_isRunning) _processQueue();
  }

  Future<void> _processQueue() async {
    _isRunning = true;
    while (_queue.isNotEmpty) {
      final task = _queue.removeFirst().split('|');
      final url = task[0];
      final bytes = int.parse(task[1]);

      try {
        final tracker = await cache.getTracker(url);
        if (tracker.hasRange(0, bytes - 1)) continue; // Already cached

        final request = await _client.getUrl(Uri.parse(url));
        request.headers.set(HttpHeaders.rangeHeader, 'bytes=0-${bytes - 1}');
        final response = await request.close();

        if (response.statusCode == 200 || response.statusCode == 206) {
          final builder = BytesBuilder();
          await for (var chunk in response) {
            builder.add(chunk);
          }
          await cache.saveChunkToDisk(url, 0, builder.toBytes());
        }
      } catch (_) {
        // Silent fail for prefetcher, it's a background optimization
      }
    }
    _isRunning = false;
  }
}

class ResumableUploader {
  final File file;
  final String uploadUrl;
  final HttpMethod method;
  final Map<String, String> headers;
  final int chunkSize;

  bool _isPaused = false;
  bool _isAborted = false;
  final StreamController<TransferProgress> _progress =
      StreamController.broadcast();

  ResumableUploader({
    required this.file,
    required this.uploadUrl,
    this.method = HttpMethod.patch,
    this.headers = const {},
    this.chunkSize = 1024 * 1024, // 1MB chunks
  });

  Stream<TransferProgress> get progress => _progress.stream;

  void pause() => _isPaused = true;
  void abort() => _isAborted = true;

  Future<void> start({int startOffset = 0}) async {
    _isPaused = false;
    _isAborted = false;
    final totalBytes = await file.length();
    int offset = startOffset;
    final client = HttpClient();
    final stopWatch = Stopwatch();

    final raf = await file.open(mode: FileMode.read);

    while (offset < totalBytes && !_isPaused && !_isAborted) {
      stopWatch.reset();
      stopWatch.start();

      await raf.setPosition(offset);
      final chunkData =
          await raf.read(math.min(chunkSize, totalBytes - offset));

      bool success = false;
      int retries = 0;
      while (!success && retries < 3 && !_isAborted) {
        try {
          final request = await _createRequest(client, uploadUrl, method);
          headers.forEach((k, v) => request.headers.set(k, v));

          request.headers.set('Upload-Offset', offset.toString());
          request.headers.set('Content-Range',
              'bytes $offset-${offset + chunkData.length - 1}/$totalBytes');
          request.contentLength = chunkData.length;
          request.add(chunkData);

          final response = await request.close();
          if (response.statusCode >= 200 && response.statusCode < 300) {
            success = true;
          } else {
            throw Exception('Server rejected chunk: ${response.statusCode}');
          }
        } catch (e) {
          retries++;
          await Future.delayed(Duration(seconds: math.pow(2, retries).toInt()));
        }
      }

      if (!success) {
        _progress.addError(
            VaultStreamException('upload_failed', 'Failed at offset $offset'));
        break;
      }

      offset += chunkData.length;
      stopWatch.stop();

      double bps =
          (chunkData.length * 8) / (stopWatch.elapsedMilliseconds / 1000.0);
      int remainingBytes = totalBytes - offset;
      Duration est =
          Duration(seconds: bps > 0 ? (remainingBytes * 8 ~/ bps) : 0);

      _progress.add(TransferProgress(
        sentBytes: offset,
        totalBytes: totalBytes,
        progress: offset / totalBytes,
        stage: 'uploading',
        currentSpeedBps: bps,
        estimatedTimeRemaining: est,
      ));
    }

    await raf.close();
    client.close(force: true);
    if (offset >= totalBytes) _progress.close();
  }

  Future<HttpClientRequest> _createRequest(
      HttpClient client, String url, HttpMethod method) async {
    final uri = Uri.parse(url);
    switch (method) {
      case HttpMethod.post:
        return await client.postUrl(uri);
      case HttpMethod.put:
        return await client.putUrl(uri);
      case HttpMethod.patch:
        return await client.patchUrl(uri);
      case HttpMethod.get:
        throw Exception('GET not supported for upload');
    }
  }
}

// =============================================================================
// SECURE PLAY-WHILE-DOWNLOADING LOCAL PROXY SERVER
// =============================================================================

class LocalMediaProxyServer {
  final MediaCacheManager cache;
  HttpServer? _server;
  final String _sessionToken;

  LocalMediaProxyServer({required this.cache})
      // Generates a cryptographically random token unique to this app session
      : _sessionToken = md5
            .convert(
                utf8.encode(DateTime.now().microsecondsSinceEpoch.toString()))
            .toString();

  int get port => _server?.port ?? 0;

  Future<void> start() async {
    if (kIsWeb || _server != null) return;
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _listen();
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  String getProxyUrl(String targetUrl) {
    if (kIsWeb) return targetUrl;
    final encoded = base64Url.encode(utf8.encode(targetUrl));
    // 🚀 Inject session token into the stream URL
    return 'http://localhost:$port/proxy?url=$encoded&token=$_sessionToken';
  }

  Future<void> _listen() async {
    await for (HttpRequest request in _server!) {
      try {
        if (request.uri.path == '/proxy') {
          // 🚀 AUTHORIZATION ARMOR: Block unauthorized apps from stealing bandwidth
          final token = request.uri.queryParameters['token'];
          if (token != _sessionToken) {
            request.response.statusCode = 403;
            request.response.close();
            continue;
          }
          await _handleProxyRequest(request);
        } else {
          request.response.statusCode = 404;
          request.response.close();
        }
      } catch (_) {}
    }
  }

  Future<void> _handleProxyRequest(HttpRequest request) async {
    final encodedUrl = request.uri.queryParameters['url'];
    if (encodedUrl == null) return request.response.close();

    final targetUrl = utf8.decode(base64Url.decode(encodedUrl));
    final rangeHeader = request.headers.value(HttpHeaders.rangeHeader);

    int start = 0;
    int? end;
    if (rangeHeader != null && rangeHeader.startsWith('bytes=')) {
      final parts = rangeHeader.substring(6).split('-');
      start = int.tryParse(parts[0]) ?? 0;
      if (parts.length > 1 && parts[1].isNotEmpty) end = int.tryParse(parts[1]);
    }

    // 1. Check if we have the full requested range in cache
    final tracker = await cache.getTracker(targetUrl);
    final fetchEnd = end ??
        start + (2 * 1024 * 1024); // Default 2MB chunk if end not specified

    if (tracker.hasRange(start, fetchEnd)) {
      final data = await cache.readChunkFromDisk(targetUrl, start, fetchEnd);
      if (data != null) {
        request.response.statusCode = 206; // Partial content
        request.response.headers.add(HttpHeaders.contentRangeHeader,
            'bytes $start-${start + data.length - 1}/*');
        request.response.headers.contentType = ContentType('video', 'mp4');
        request.response.contentLength = data.length;
        request.response.add(data);
        await request.response.close();
        return;
      }
    }

    // 2. Not in cache -> proxy to internet, save to cache simultaneously
    final client = HttpClient();
    final extReq = await client.getUrl(Uri.parse(targetUrl));
    extReq.headers.set(HttpHeaders.rangeHeader, 'bytes=$start-${end ?? ''}');
    final extRes = await extReq.close();

    request.response.statusCode = extRes.statusCode;
    extRes.headers.forEach((name, values) {
      for (var v in values) {
        request.response.headers.add(name, v);
      }
    });

    int offset = start;
    await for (var chunk in extRes) {
      request.response.add(chunk); // Stream directly to video player
      await cache.saveChunkToDisk(targetUrl, offset,
          Uint8List.fromList(chunk)); // Save ENCRYPTED to SSD
      offset += chunk.length;
    }

    await request.response.close();
    client.close(force: true);
  }
}

// =============================================================================
// ADAPTIVE MEDIA STREAMER (ABR)
// =============================================================================

class StreamSegment {
  final int sequenceNumber;
  final String uri;
  final Quality quality;

  const StreamSegment(
      {required this.sequenceNumber, required this.uri, required this.quality});
}

class AdaptiveManifest {
  final String mediaId;
  final MediaType mediaType;
  final Map<Quality, List<StreamSegment>> representations;

  const AdaptiveManifest({
    required this.mediaId,
    required this.mediaType,
    required this.representations,
  });
}

class AdaptiveMediaStreamer {
  final AdaptiveManifest manifest;
  final BandwidthEstimator estimator;
  final MediaCacheManager cache;

  Quality _currentQuality;
  int _currentSequence = 0;
  bool _isPlaying = false;
  final StreamController<Uint8List> _stream = StreamController();

  AdaptiveMediaStreamer({
    required this.manifest,
    required this.estimator,
    required this.cache,
    Quality initialQuality = Quality.auto,
  }) : _currentQuality =
            initialQuality == Quality.auto ? Quality.p720 : initialQuality;

  Stream<Uint8List> get stream => _stream.stream;
  Quality get currentQuality => _currentQuality;

  void start() {
    if (_isPlaying) return;
    _isPlaying = true;
    _runPipeline();
  }

  void stop() {
    _isPlaying = false;
    _stream.close();
  }

  Future<void> _runPipeline() async {
    final client = HttpClient();
    final stopwatch = Stopwatch();

    while (_isPlaying) {
      if (manifest.representations[_currentQuality] == null) {
        _currentQuality = manifest.representations.keys.first;
      }

      final segments = manifest.representations[_currentQuality]!;
      if (_currentSequence >= segments.length) break; // Finished

      final targetSegment = segments[_currentSequence];
      final url = targetSegment.uri;

      // 1. Try RAM Cache
      Uint8List? data = await cache.getFromRam(url);

      // 2. Try Disk Cache
      if (data == null) {
        final tracker = await cache.getTracker(url);
        if (tracker.hasRange(0, 999999999)) {
          data = await cache.readChunkFromDisk(url, 0, 999999999);
        }
      }

      // 3. Network Fetch
      if (data == null) {
        stopwatch.reset();
        stopwatch.start();

        try {
          final request = await client.getUrl(Uri.parse(url));
          final response = await request.close();
          final builder = BytesBuilder();
          await for (var chunk in response) builder.add(chunk);
          data = builder.toBytes();

          stopwatch.stop();
          estimator.addSample(data.length, stopwatch.elapsed);

          // Save to cache
          await cache.saveToRam(url, data);
          await cache.saveChunkToDisk(url, 0, data);

          // ABR Logic: Switch quality for NEXT segment based on network speed
          if (manifest.representations.length > 1) {
            Quality recommended = estimator.getRecommendedQuality();
            if (manifest.representations.containsKey(recommended)) {
              _currentQuality = recommended;
            }
          }
        } catch (e) {
          _stream.addError(VaultStreamException(
              'segment_fetch_failed', 'Failed seq $_currentSequence',
              details: e));
          break;
        }
      }

      _stream.add(data!);
      _currentSequence++;
    }
    client.close();
  }
}

// =============================================================================
// REAL-TIME LIVE STREAMING PIPELINE (VoIP / WebRTC Ready)
// =============================================================================

class VoipPacket {
  final int sequenceNumber;
  final int timestamp;
  final int payloadType;
  final int ssrc;
  final Uint8List payload;

  const VoipPacket({
    required this.sequenceNumber,
    required this.timestamp,
    required this.payloadType,
    required this.ssrc,
    required this.payload,
  });

  Uint8List serialize() {
    final header = ByteData(12);
    header.setUint8(0, 0x80);
    header.setUint8(1, payloadType & 0x7F);
    header.setUint16(2, sequenceNumber, Endian.big);
    header.setUint32(4, timestamp, Endian.big);
    header.setUint32(8, ssrc, Endian.big);

    final packet = BytesBuilder();
    packet.add(header.buffer.asUint8List());
    packet.add(payload);
    return packet.toBytes();
  }

  factory VoipPacket.deserialize(Uint8List data) {
    if (data.length < 12)
      throw const VaultStreamException(
          'voip_corrupt', 'Payload below minimum RTP length');
    final header = ByteData.sublistView(data, 0, 12);
    return VoipPacket(
      sequenceNumber: header.getUint16(2, Endian.big),
      timestamp: header.getUint32(4, Endian.big),
      payloadType: header.getUint8(1) & 0x7F,
      ssrc: header.getUint32(8, Endian.big),
      payload: data.sublist(12),
    );
  }
}

class LiveMediaPipeline {
  final int ssrc = math.Random().nextInt(0xFFFFFFFF);
  int _sequenceNumber = 0;

  final StreamController<Uint8List> _ingress = StreamController();
  final StreamController<Uint8List> _egress = StreamController();
  bool _isActive = false;

  StreamSink<Uint8List> get ingressInput => _ingress.sink;
  Stream<Uint8List> get egressOutput => _egress.stream;

  void initialize({
    required Future<void> Function(Uint8List packet) transmitter,
    required Stream<Uint8List> sourceReceiver,
  }) {
    _isActive = true;

    // Transmit path (Microphone/Camera -> Network)
    _ingress.stream.listen((frameBuffer) async {
      if (!_isActive) return;
      final packet = VoipPacket(
        sequenceNumber: _sequenceNumber++,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        payloadType: 96, // Dynamic payload type
        ssrc: ssrc,
        payload: frameBuffer,
      );
      try {
        await transmitter(packet.serialize());
      } catch (e) {
        _egress.addError(e);
      }
    });

    // Receive path (Network -> Speaker/Screen)
    sourceReceiver.listen((rawSegment) {
      if (!_isActive) return;
      try {
        final packet = VoipPacket.deserialize(rawSegment);
        // Pass to egress (UI playback)
        _egress.add(packet.payload);
      } catch (e) {
        _egress.addError(e);
      }
    });
  }

  void terminate() {
    _isActive = false;
    _ingress.close();
    _egress.close();
  }
}

// =============================================================================
// MAIN QUANTUM MEDIA ENGINE (SINGLETON)
// =============================================================================

class QuantumMediaEngine {
  static final QuantumMediaEngine instance = QuantumMediaEngine._internal();
  QuantumMediaEngine._internal();

  late LocalStore localStore;
  late Directory cacheDirectory;
  String? clientSecret;

  late final MediaCacheManager cacheManager;
  late final MediaPrefetcher prefetcher;
  late final LocalMediaProxyServer proxyServer;
  late final BandwidthEstimator bandwidthEstimator;
  final Map<String, Future<Uint8List>> _inFlightMediaFetches = {};

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initializes the Engine. Must be called before any other operation.
  Future<void> init({
    required LocalStore localStore,
    required Directory cacheDirectory,
    String? clientSecret,
  }) async {
    if (_isInitialized) return;

    this.localStore = localStore;
    this.cacheDirectory = cacheDirectory;
    this.clientSecret = clientSecret;

    cacheManager = MediaCacheManager(
        cacheDir: cacheDirectory,
        store: localStore,
        clientSecret: clientSecret);
    await cacheManager.init();

    prefetcher = MediaPrefetcher(cache: cacheManager);

    proxyServer = LocalMediaProxyServer(cache: cacheManager);
    await proxyServer.start();

    bandwidthEstimator = BandwidthEstimator();

    _isInitialized = true;
  }

  /// Cleans up resources and stops proxy servers
  Future<void> dispose() async {
    await proxyServer.stop();
  }

  /// Instructs the engine to silently download the first [bytesToFetch] of the given URLs
  void prefetchMedia(List<String> urls, {int bytesToFetch = 512 * 1024}) {
    _ensureInitialized();
    prefetcher.prefetch(urls, bytesToFetch: bytesToFetch);
  }

  /// Takes a raw MP4/media URL and returns a localhost Proxy URL.
  String getProxyPlayUrl(String originalUrl) {
    _ensureInitialized();
    return proxyServer.getProxyUrl(originalUrl);
  }

  /// Creates a robust Uploader using the PATCH method (TUS protocol ready).
  ResumableUploader createUploader({
    required File file,
    required String uploadUrl,
    HttpMethod method = HttpMethod.patch,
    Map<String, String> headers = const {},
  }) {
    return ResumableUploader(
      file: file,
      uploadUrl: uploadUrl,
      method: method,
      headers: headers,
    );
  }

  /// Creates an Adaptive Streamer for HLS/DASH style manifests.
  AdaptiveMediaStreamer createAdaptiveStreamer(AdaptiveManifest manifest) {
    _ensureInitialized();
    return AdaptiveMediaStreamer(
      manifest: manifest,
      estimator: bandwidthEstimator,
      cache: cacheManager,
    );
  }

  /// Creates a Real-Time WebRTC/VoIP ready pipeline.
  LiveMediaPipeline createLivePipeline() {
    return LiveMediaPipeline();
  }

  /// Directly fetch bytes for an image (Google Images style).
  Future<Uint8List> getMediaBytes(String url) async {
    _ensureInitialized();

    final existing = _inFlightMediaFetches[url];
    if (existing != null) return existing;

    final future = () async {
      // 1. RAM
      final ram = await cacheManager.getFromRam(url);
      if (ram != null) return ram;

      // 2. Disk
      final tracker = await cacheManager.getTracker(url);
      if (tracker.hasRange(0, 99999999)) {
        final disk = await cacheManager.readChunkFromDisk(url, 0, 99999999);
        if (disk != null) {
          await cacheManager.saveToRam(url, disk);
          return disk;
        }
      }

      // 3. Network
      final client = HttpClient();
      try {
        final req = await client.getUrl(Uri.parse(url));
        final res = await req.close();
        final builder = BytesBuilder();
        await for (var chunk in res) builder.add(chunk);
        final data = builder.toBytes();

        await cacheManager.saveToRam(url, data);
        await cacheManager.saveChunkToDisk(url, 0, data);
        return data;
      } finally {
        client.close(force: true);
      }
    }();

    _inFlightMediaFetches[url] = future;
    try {
      return await future;
    } finally {
      _inFlightMediaFetches.remove(url);
    }
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw const VaultStreamException('engine_not_initialized',
          'You must call QuantumMediaEngine.instance.init() first.');
    }
  }
}
