import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quantum_layout/quantum.dart';

Uint8List makePatternBytes(int length, {int seed = 0}) {
  return Uint8List.fromList(
    List<int>.generate(length, (i) => (i + seed) % 256),
  );
}

Future<void> waitUntil(
  FutureOr<bool> Function() predicate, {
  Duration timeout = const Duration(seconds: 8),
  Duration step = const Duration(milliseconds: 20),
  String? reason,
}) async {
  final sw = Stopwatch()..start();
  while (!await predicate()) {
    if (sw.elapsed > timeout) {
      fail(reason ?? 'Timed out waiting for condition.');
    }
    await Future<void>.delayed(step);
  }
}

Future<Uint8List> consolidateHttpBody(HttpClientResponse response) async {
  final bytes = <int>[];
  await for (final chunk in response) {
    bytes.addAll(chunk);
  }
  return Uint8List.fromList(bytes);
}

class MediaOriginServer {
  MediaOriginServer({
    required this.body,
    this.chunkSize = 16 * 1024,
    this.perChunkDelay = Duration.zero,
  });

  final Uint8List body;
  final int chunkSize;
  final Duration perChunkDelay;

  HttpServer? _server;
  final Map<String, int> requestsByPath = {};
  int totalRequests = 0;

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server!.listen(_handleRequest);
  }

  Uri uriFor(String path) {
    final server = _server;
    if (server == null) {
      throw StateError('Server not started');
    }
    return Uri.parse('http://${server.address.host}:${server.port}$path');
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  Future<void> _handleRequest(HttpRequest request) async {
    totalRequests++;
    requestsByPath.update(request.uri.path, (value) => value + 1,
        ifAbsent: () => 1);

    if (request.uri.path == '/health') {
      request.response.statusCode = 200;
      request.response.write('ok');
      await request.response.close();
      return;
    }

    final rangeHeader = request.headers.value(HttpHeaders.rangeHeader);
    if (rangeHeader != null && rangeHeader.startsWith('bytes=')) {
      final parts = rangeHeader.substring(6).split('-');
      final start = int.tryParse(parts.first) ?? 0;
      final parsedEnd = parts.length > 1 && parts[1].isNotEmpty
          ? int.tryParse(parts[1])
          : null;
      final end = parsedEnd == null
          ? body.length - 1
          : parsedEnd.clamp(0, body.length - 1);
      final slice = body.sublist(start.clamp(0, body.length), end + 1);

      request.response.statusCode = HttpStatus.partialContent;
      request.response.headers.contentType =
          ContentType('application', 'octet-stream');
      request.response.headers.set(
        HttpHeaders.contentRangeHeader,
        'bytes $start-$end/${body.length}',
      );
      request.response.contentLength = slice.length;

      for (var offset = 0; offset < slice.length; offset += chunkSize) {
        if (perChunkDelay != Duration.zero) {
          await Future<void>.delayed(perChunkDelay);
        }
        final next = (offset + chunkSize).clamp(0, slice.length);
        request.response.add(slice.sublist(offset, next));
      }
      await request.response.close();
      return;
    }

    request.response.statusCode = HttpStatus.ok;
    request.response.headers.contentType =
        ContentType('application', 'octet-stream');
    request.response.contentLength = body.length;
    for (var offset = 0; offset < body.length; offset += chunkSize) {
      if (perChunkDelay != Duration.zero) {
        await Future<void>.delayed(perChunkDelay);
      }
      final next = (offset + chunkSize).clamp(0, body.length);
      request.response.add(body.sublist(offset, next));
    }
    await request.response.close();
  }
}

class UploadCaptureServer {
  HttpServer? _server;
  int requestCount = 0;
  final List<Map<String, String>> headersSeen = [];
  final List<Uint8List> bodies = [];
  final List<int> offsets = [];

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server!.listen((request) async {
      requestCount++;
      final chunks = <int>[];
      await for (final chunk in request) {
        chunks.addAll(chunk);
      }
      bodies.add(Uint8List.fromList(chunks));

      final extractedHeaders = <String, String>{};
      request.headers.forEach((name, values) {
        extractedHeaders[name] = request.headers.value(name) ?? '';
      });
      headersSeen.add(extractedHeaders);

      offsets.add(
          int.tryParse(request.headers.value('Upload-Offset') ?? '0') ?? 0);
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
    });
  }

  Uri get uri {
    final server = _server;
    if (server == null) throw StateError('Server not started');
    return Uri.parse('http://${server.address.host}:${server.port}/upload');
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ADD THIS LINE to allow real HTTP connections to your local test servers
  HttpOverrides.global = null;

  group('RangeTracker', () {
    test('merges adjacent ranges into a single contiguous block', () {
      final tracker = RangeTracker();
      tracker.addRange(0, 99);
      tracker.addRange(100, 199);
      expect(tracker.hasRange(0, 199), isTrue);
      expect(tracker.getMissingRanges(0, 199), isEmpty);
    });

    test('merges overlapping ranges correctly', () {
      final tracker = RangeTracker();
      tracker.addRange(0, 100);
      tracker.addRange(50, 150);
      expect(tracker.hasRange(0, 150), isTrue);
      expect(tracker.getMissingRanges(0, 150), isEmpty);
    });

    test('returns the exact missing gap in the middle', () {
      final tracker = RangeTracker();
      tracker.addRange(0, 99);
      tracker.addRange(200, 299);
      final missing = tracker.getMissingRanges(0, 299);
      expect(missing, hasLength(1));
      expect(missing.first.start, 100);
      expect(missing.first.end, 199);
    });

    test('serializes and deserializes losslessly', () {
      final tracker = RangeTracker();
      tracker.addRange(0, 99);
      tracker.addRange(150, 299);
      final raw = tracker.serialize();
      final restored = RangeTracker();
      restored.deserialize(raw);
      expect(restored.hasRange(0, 99), isTrue);
      expect(restored.hasRange(150, 299), isTrue);
      expect(restored.getMissingRanges(0, 299).first.start, 100);
    });

    test('empty tracker reports the whole request as missing', () {
      final tracker = RangeTracker();
      final missing = tracker.getMissingRanges(50, 149);
      expect(missing, hasLength(1));
      expect(missing.single.start, 50);
      expect(missing.single.end, 149);
    });

    test('merging keeps sparse ranges separate', () {
      final tracker = RangeTracker();
      tracker.addRange(0, 9);
      tracker.addRange(20, 29);
      tracker.addRange(40, 49);
      final missing = tracker.getMissingRanges(0, 49);
      expect(missing, hasLength(2));
      expect(missing.first.start, 10);
      expect(missing.first.end, 19);
      expect(missing.last.start, 30);
      expect(missing.last.end, 39);
    });
  });

  group('MediaCacheManager', () {
    late Directory tempDir;
    late MemoryLocalStore store;

    setUp(() async {
      tempDir =
          await Directory.systemTemp.createTemp('quantum_media_cache_test_');
      store = MemoryLocalStore();
      await store.init();
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('initializes the cache directory', () async {
      final cache = MediaCacheManager(cacheDir: tempDir, store: store);
      await cache.init();
      expect(await tempDir.exists(), isTrue);
    });

    test('stores and returns RAM cache entries', () async {
      final cache = MediaCacheManager(cacheDir: tempDir, store: store);
      final data = makePatternBytes(1024, seed: 11);
      await cache.saveToRam('https://example.com/image.jpg', data);

      final restored = await cache.getFromRam('https://example.com/image.jpg');
      expect(restored, isNotNull);
      expect(restored!.toList(), equals(data.toList()));
    });

    test('evicts the oldest RAM cache entry when over the limit', () async {
      final cache = MediaCacheManager(
        cacheDir: tempDir,
        store: store,
        maxRamCacheBytes: 10,
      );
      await cache.saveToRam(
          'https://example.com/a', Uint8List.fromList([1, 1, 1, 1]));
      await cache.saveToRam(
          'https://example.com/b', Uint8List.fromList([2, 2, 2, 2]));
      await cache.saveToRam(
          'https://example.com/c', Uint8List.fromList([3, 3, 3, 3]));

      expect(await cache.getFromRam('https://example.com/a'), isNull);
      expect(await cache.getFromRam('https://example.com/b'), isNotNull);
      expect(await cache.getFromRam('https://example.com/c'), isNotNull);
    });

    test('persists disk chunks and restores them without encryption secret',
        () async {
      final cache = MediaCacheManager(cacheDir: tempDir, store: store);
      await cache.init();
      final url = 'https://example.com/video.mp4';
      final chunk = makePatternBytes(4096, seed: 7);

      await cache.saveChunkToDisk(url, 0, chunk);
      final restored = await cache.readChunkFromDisk(url, 0, chunk.length - 1);

      expect(restored, isNotNull);
      expect(restored!.toList(), equals(chunk.toList()));
    });

    test('encrypts disk chunks when a client secret is supplied', () async {
      final cache = MediaCacheManager(
        cacheDir: tempDir,
        store: store,
        clientSecret: 'super-secret-key',
      );
      await cache.init();
      final url = 'https://example.com/secure.mp4';
      final chunk = makePatternBytes(2048, seed: 33);

      await cache.saveChunkToDisk(url, 0, chunk);

      final key = md5.convert(utf8.encode(url)).toString();
      final rawFile = File('${tempDir.path}/$key.media');
      final diskBytes = await rawFile.readAsBytes();

      expect(diskBytes, isNot(equals(chunk.toList())),
          reason: 'Encrypted on disk bytes should differ from plaintext');
      final restored = await cache.readChunkFromDisk(url, 0, chunk.length - 1);
      expect(restored!.toList(), equals(chunk.toList()));
    });

    test('persists byte-range trackers across fresh cache instances', () async {
      final url = 'https://example.com/ranges.mp4';
      final cache1 = MediaCacheManager(cacheDir: tempDir, store: store);
      await cache1.init();
      await cache1.saveChunkToDisk(url, 0, makePatternBytes(512, seed: 1));
      await cache1.saveChunkToDisk(url, 512, makePatternBytes(512, seed: 2));

      final cache2 = MediaCacheManager(cacheDir: tempDir, store: store);
      final tracker = await cache2.getTracker(url);
      expect(tracker.hasRange(0, 1023), isTrue);
      expect(tracker.getMissingRanges(0, 1023), isEmpty);
    });

    test('returns null for missing disk content', () async {
      final cache = MediaCacheManager(cacheDir: tempDir, store: store);
      final data =
          await cache.readChunkFromDisk('https://example.com/missing', 0, 100);
      expect(data, isNull);
    });
  });

  group('BandwidthEstimator', () {
    test('uses a sane default before any samples are added', () {
      final estimator = BandwidthEstimator();
      expect(estimator.currentBps, equals(5000000));
      expect(estimator.getRecommendedQuality(), equals(Quality.p720));
    });

    test('maps low bandwidth to a low quality tier', () {
      final estimator = BandwidthEstimator();
      estimator.addSample(
          100 * 1024, const Duration(milliseconds: 2000)); // ~409.6 kbps
      expect(estimator.getRecommendedQuality(), equals(Quality.p240));
    });

    test('maps 3G-like throughput to a conservative quality tier', () {
      final estimator = BandwidthEstimator();
      estimator.addSample(
          250 * 1024, const Duration(milliseconds: 2000)); // ~1 Mbps
      expect(
          estimator.getRecommendedQuality(), anyOf(Quality.p360, Quality.p480));
    });

    test('maps mid bandwidth to 480p', () {
      final estimator = BandwidthEstimator();
      estimator.addSample(
          500 * 1024, const Duration(milliseconds: 2000)); // ~2 Mbps
      expect(estimator.getRecommendedQuality(), equals(Quality.p480));
    });

    test('maps good bandwidth to 720p', () {
      final estimator = BandwidthEstimator();
      estimator.addSample(
          800 * 1024, const Duration(milliseconds: 1500)); // ~4.3 Mbps
      expect(estimator.getRecommendedQuality(), equals(Quality.p720));
    });

    test('maps very good bandwidth to 1080p', () {
      final estimator = BandwidthEstimator();
      estimator.addSample(
          2 * 1024 * 1024, const Duration(milliseconds: 2000)); // ~8.4 Mbps
      expect(estimator.getRecommendedQuality(), equals(Quality.p1080));
    });

    test('maps excellent bandwidth to 4k', () {
      final estimator = BandwidthEstimator();
      estimator.addSample(
          4 * 1024 * 1024, const Duration(milliseconds: 1000)); // ~33.5 Mbps
      expect(estimator.getRecommendedQuality(), equals(Quality.p4k));
    });

    test('ignores zero-duration samples safely', () {
      final estimator = BandwidthEstimator();
      estimator.addSample(12345, Duration.zero);
      expect(estimator.currentBps, equals(5000000));
    });

    test('smoothing follows the moving average instead of a single spike', () {
      final estimator = BandwidthEstimator();
      estimator.addSample(
          100 * 1024, const Duration(milliseconds: 2000)); // slow
      estimator.addSample(
          8 * 1024 * 1024, const Duration(milliseconds: 500)); // fast spike
      expect(estimator.currentBps, greaterThan(0));
      expect(estimator.getRecommendedQuality(), isNot(Quality.p240));
    });
  });

  group('MediaPrefetcher', () {
    late Directory tempDir;
    late MemoryLocalStore store;
    late MediaCacheManager cache;
    late MediaOriginServer origin;

    setUp(() async {
      tempDir =
          await Directory.systemTemp.createTemp('quantum_media_prefetch_test_');
      store = MemoryLocalStore();
      await store.init();
      cache = MediaCacheManager(cacheDir: tempDir, store: store);
      await cache.init();
      origin = MediaOriginServer(
        body: makePatternBytes(128 * 1024, seed: 44),
        perChunkDelay: const Duration(milliseconds: 10),
      );
      await origin.start();
    });

    tearDown(() async {
      await origin.stop();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('prefetches the requested range and persists it to disk', () async {
      final prefetcher = MediaPrefetcher(cache: cache);
      final url = origin.uriFor('/prefetch-a').toString();

      prefetcher.prefetch([url], bytesToFetch: 32 * 1024);

      await waitUntil(() async {
        final tracker = await cache.getTracker(url);
        return tracker.hasRange(0, 32 * 1024 - 1);
      });

      expect(origin.requestsByPath['/prefetch-a'], equals(1));

      final bytes = await cache.readChunkFromDisk(url, 0, 32 * 1024 - 1);
      expect(bytes, isNotNull);
      expect(bytes!.length, equals(32 * 1024));
    });

    test('does not fetch the same URL twice while it is already queued',
        () async {
      final prefetcher = MediaPrefetcher(cache: cache);
      final url = origin.uriFor('/prefetch-b').toString();

      prefetcher.prefetch([url, url], bytesToFetch: 16 * 1024);

      await waitUntil(() async {
        final tracker = await cache.getTracker(url);
        return tracker.hasRange(0, 16 * 1024 - 1);
      });

      expect(origin.requestsByPath['/prefetch-b'], equals(1));
    });
  });

  group('LocalMediaProxyServer', () {
    late Directory tempDir;
    late MemoryLocalStore store;
    late MediaCacheManager cache;
    late MediaOriginServer origin;
    late LocalMediaProxyServer proxy;

    setUp(() async {
      tempDir =
          await Directory.systemTemp.createTemp('quantum_media_proxy_test_');
      store = MemoryLocalStore();
      await store.init();
      cache = MediaCacheManager(cacheDir: tempDir, store: store);
      await cache.init();
      origin = MediaOriginServer(
        body: makePatternBytes(64 * 1024, seed: 99),
      );
      await origin.start();
      proxy = LocalMediaProxyServer(cache: cache);
      await proxy.start();
    });

    tearDown(() async {
      await proxy.stop();
      await origin.stop();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('builds a loopback proxy URL that carries a session token', () {
      final target = origin.uriFor('/video.mp4').toString();
      final proxyUrl = proxy.getProxyUrl(target);
      expect(proxyUrl, contains('localhost'));
      expect(proxyUrl, contains('token='));
      expect(proxyUrl, contains('url='));
    });

    test('rejects requests with an invalid token', () async {
      final target = origin.uriFor('/video-a.mp4').toString();
      final proxyUrl = Uri.parse(proxy.getProxyUrl(target));
      final forged = proxyUrl.replace(queryParameters: {
        ...proxyUrl.queryParameters,
        'token': 'invalid-token',
      });

      final client = HttpClient();
      final response = await (await client.getUrl(forged)).close();
      expect(response.statusCode, equals(HttpStatus.forbidden));
      client.close(force: true);
    });

    test('streams a range request and fills the cache', () async {
      final target = origin.uriFor('/video-b.mp4').toString();
      final proxyUrl = Uri.parse(proxy.getProxyUrl(target));
      final client = HttpClient();

      final req = await client.getUrl(proxyUrl);
      req.headers.set(HttpHeaders.rangeHeader, 'bytes=0-8191');
      final res = await req.close();
      final bytes = await consolidateHttpBody(res);

      expect(res.statusCode, anyOf(HttpStatus.partialContent, HttpStatus.ok));
      expect(bytes.length, equals(8192));
      expect(origin.requestsByPath['/video-b.mp4'], equals(1));

      final tracker = await cache.getTracker(target);
      expect(tracker.hasRange(0, 8191), isTrue);

      final req2 = await client.getUrl(proxyUrl);
      req2.headers.set(HttpHeaders.rangeHeader, 'bytes=0-8191');
      final res2 = await req2.close();
      final bytes2 = await consolidateHttpBody(res2);

      expect(bytes2.length, equals(8192));
      expect(origin.requestsByPath['/video-b.mp4'], equals(1),
          reason: 'Second identical request should be served from cache');
      client.close(force: true);
    });
  });

  group('QuantumMediaEngine', () {
    late Directory tempDir;
    late MemoryLocalStore store;
    late MediaOriginServer origin;

    setUpAll(() async {
      tempDir =
          await Directory.systemTemp.createTemp('quantum_media_engine_test_');
      store = MemoryLocalStore();
      await store.init();
      await QuantumMediaEngine.instance.init(
        localStore: store,
        cacheDirectory: tempDir,
        clientSecret: 'engine-secret',
      );
    });

    tearDownAll(() async {
      await QuantumMediaEngine.instance.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    setUp(() async {
      origin = MediaOriginServer(
        body: makePatternBytes(256 * 1024, seed: 17),
        perChunkDelay: const Duration(milliseconds: 50),
      );
      await origin.start();
    });

    tearDown(() async {
      await origin.stop();
    });

    test('deduplicates concurrent in-flight media fetches', () async {
      final url = origin.uriFor('/dedupe.mp4').toString();

      final results = await Future.wait([
        QuantumMediaEngine.instance.getMediaBytes(url),
        QuantumMediaEngine.instance.getMediaBytes(url),
      ]);

      expect(results[0].toList(), equals(results[1].toList()));
      expect(origin.requestsByPath['/dedupe.mp4'], equals(1));
    });

    test('serves a second fetch from cache without hitting the origin again',
        () async {
      final url = origin.uriFor('/cache-hit.mp4').toString();

      final first = await QuantumMediaEngine.instance.getMediaBytes(url);
      final second = await QuantumMediaEngine.instance.getMediaBytes(url);

      expect(first.toList(), equals(second.toList()));
      expect(origin.requestsByPath['/cache-hit.mp4'], equals(1));
    });

    test('prefetchMedia warms the cache before the main fetch happens',
        () async {
      final url = origin.uriFor('/prefetch-warm.mp4').toString();
      QuantumMediaEngine.instance.prefetchMedia([url], bytesToFetch: 64 * 1024);

      await waitUntil(
          () async => origin.requestsByPath['/prefetch-warm.mp4'] != null);
      final bytes = await QuantumMediaEngine.instance.getMediaBytes(url);

      expect(bytes.isNotEmpty, isTrue);
      expect(origin.requestsByPath['/prefetch-warm.mp4'], equals(2));
    });
  });

  group('ResumableUploader', () {
    late Directory tempDir;
    late UploadCaptureServer uploadServer;

    setUp(() async {
      tempDir =
          await Directory.systemTemp.createTemp('quantum_media_upload_test_');
      uploadServer = UploadCaptureServer();
      await uploadServer.start();
    });

    tearDown(() async {
      await uploadServer.stop();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('uploads a file in chunks with offset headers and progress events',
        () async {
      final file = File('${tempDir.path}/video.bin');
      final payload = makePatternBytes(2 * 1024 * 1024, seed: 77);
      await file.writeAsBytes(payload);

      final uploader = ResumableUploader(
        file: file,
        uploadUrl: uploadServer.uri.toString(),
        chunkSize: 512 * 1024,
      );

      final progressEvents = <TransferProgress>[];
      final sub = uploader.progress.listen(progressEvents.add);

      await uploader.start();

      await Future<void>.delayed(const Duration(milliseconds: 200));
      await sub.cancel();

      expect(uploadServer.requestCount, equals(4));
      expect(uploadServer.offsets,
          equals([0, 512 * 1024, 1024 * 1024, 1536 * 1024]));
      expect(progressEvents, isNotEmpty);
      expect(progressEvents.last.progress, closeTo(1.0, 0.001));
      expect(progressEvents.last.stage, contains('upload'));
    });

    test('aborts before the full upload completes', () async {
      final file = File('${tempDir.path}/abort.bin');
      final payload = makePatternBytes(2 * 1024 * 1024, seed: 3);
      await file.writeAsBytes(payload);

      final uploader = ResumableUploader(
        file: file,
        uploadUrl: uploadServer.uri.toString(),
        chunkSize: 256 * 1024,
      );

      final progressEvents = <TransferProgress>[];
      final sub = uploader.progress.listen(progressEvents.add);

      unawaited(Future<void>(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        uploader.abort();
      }));

      await uploader.start();

      await Future<void>.delayed(const Duration(milliseconds: 100));
      await sub.cancel();

      expect(uploadServer.requestCount, lessThan(8));
      expect(progressEvents, isNotEmpty);
    });
  });

  group('VoipPacket and LiveMediaPipeline', () {
    test('serializes and deserializes RTP-style packets losslessly', () {
      final packet = VoipPacket(
        sequenceNumber: 1234,
        timestamp: 987654321,
        payloadType: 96,
        ssrc: 555,
        payload: makePatternBytes(32, seed: 10),
      );

      final raw = packet.serialize();
      final restored = VoipPacket.deserialize(raw);

      expect(restored.sequenceNumber, equals(1234));
      expect(restored.timestamp, equals(987654321));
      expect(restored.payloadType, equals(96));
      expect(restored.ssrc, equals(555));
      expect(restored.payload.toList(), equals(packet.payload.toList()));
    });

    test('rejects corrupt packets shorter than the RTP minimum header', () {
      expect(
        () => VoipPacket.deserialize(Uint8List.fromList([1, 2, 3])),
        throwsA(isA<VaultStreamException>()),
      );
    });

    test('round-trips frames through the live media pipeline', () async {
      final pipeline = LiveMediaPipeline();
      final transmitted = <Uint8List>[];
      final received = <Uint8List>[];

      final receivedCompleter = Completer<void>();

      pipeline.initialize(
        transmitter: (packet) async => transmitted.add(packet),
        sourceReceiver: Stream<Uint8List>.fromIterable([
          VoipPacket(
            sequenceNumber: 1,
            timestamp: 111,
            payloadType: 96,
            ssrc: pipeline.ssrc,
            payload: Uint8List.fromList([9, 8, 7]),
          ).serialize(),
        ]),
      );

      pipeline.egressOutput.listen((payload) {
        received.add(payload);
        if (!receivedCompleter.isCompleted) {
          receivedCompleter.complete();
        }
      });

      pipeline.ingressInput.add(Uint8List.fromList([1, 2, 3, 4]));

      await receivedCompleter.future.timeout(const Duration(seconds: 2));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(transmitted, isNotEmpty);
      expect(received, isNotEmpty);
      expect(received.single.toList(), equals([9, 8, 7]));

      pipeline.terminate();
    });
  });

  group('AdaptiveMediaStreamer', () {
    late Directory tempDir;
    late MemoryLocalStore store;
    late MediaCacheManager cache;
    late MediaOriginServer slowOrigin;
    late MediaOriginServer fastOrigin;

    setUp(() async {
      tempDir =
          await Directory.systemTemp.createTemp('quantum_media_abr_test_');
      store = MemoryLocalStore();
      await store.init();
      cache = MediaCacheManager(cacheDir: tempDir, store: store);
      await cache.init();

      slowOrigin = MediaOriginServer(
        body: makePatternBytes(256 * 1024, seed: 123),
        perChunkDelay: const Duration(milliseconds: 150),
      );
      await slowOrigin.start();

      fastOrigin = MediaOriginServer(
        body: makePatternBytes(256 * 1024, seed: 124),
        perChunkDelay: Duration.zero,
      );
      await fastOrigin.start();
    });

    tearDown(() async {
      await slowOrigin.stop();
      await fastOrigin.stop();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('switches down to a lower quality tier on slow network', () async {
      final manifest = AdaptiveManifest(
        mediaId: 'slow-feed',
        mediaType: MediaType.video,
        representations: {
          Quality.p1080: [
            StreamSegment(
                sequenceNumber: 0,
                uri: slowOrigin.uriFor('/slow-1').toString(),
                quality: Quality.p1080),
            StreamSegment(
                sequenceNumber: 1,
                uri: slowOrigin.uriFor('/slow-2').toString(),
                quality: Quality.p1080),
          ],
          Quality.p360: [
            StreamSegment(
                sequenceNumber: 0,
                uri: slowOrigin.uriFor('/slow-1-low').toString(),
                quality: Quality.p360),
            StreamSegment(
                sequenceNumber: 1,
                uri: slowOrigin.uriFor('/slow-2-low').toString(),
                quality: Quality.p360),
          ],
        },
      );

      final streamer = AdaptiveMediaStreamer(
        manifest: manifest,
        estimator: BandwidthEstimator(),
        cache: cache,
        initialQuality: Quality.p1080,
      );

      final emitted = <Uint8List>[];
      final sub = streamer.stream.listen(emitted.add);
      streamer.start();

      await waitUntil(() async => emitted.length >= 2,
          timeout: const Duration(seconds: 8));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      streamer.stop();
      await sub.cancel();

      expect(emitted, isNotEmpty);
      expect(streamer.currentQuality, equals(Quality.p360),
          reason: 'Slow network should force the next segment to a lower tier');
    });

    test('switches up to a higher quality tier on fast network', () async {
      final manifest = AdaptiveManifest(
        mediaId: 'fast-feed',
        mediaType: MediaType.video,
        representations: {
          Quality.p240: [
            StreamSegment(
                sequenceNumber: 0,
                uri: fastOrigin.uriFor('/fast-1').toString(),
                quality: Quality.p240),
            StreamSegment(
                sequenceNumber: 1,
                uri: fastOrigin.uriFor('/fast-2').toString(),
                quality: Quality.p240),
          ],
          Quality.p4k: [
            StreamSegment(
                sequenceNumber: 0,
                uri: fastOrigin.uriFor('/fast-1-hd').toString(),
                quality: Quality.p4k),
            StreamSegment(
                sequenceNumber: 1,
                uri: fastOrigin.uriFor('/fast-2-hd').toString(),
                quality: Quality.p4k),
          ],
        },
      );

      final streamer = AdaptiveMediaStreamer(
        manifest: manifest,
        estimator: BandwidthEstimator(),
        cache: cache,
        initialQuality: Quality.p240,
      );

      final emitted = <Uint8List>[];
      final sub = streamer.stream.listen(emitted.add);
      streamer.start();

      await waitUntil(() async => emitted.length >= 2,
          timeout: const Duration(seconds: 5));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      streamer.stop();
      await sub.cancel();

      expect(emitted, isNotEmpty);
      expect(streamer.currentQuality, equals(Quality.p4k),
          reason: 'Fast network should upgrade the next segment tier');
    });
  });
}
