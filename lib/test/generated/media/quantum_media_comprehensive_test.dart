import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/src/features/media/quantum_media_engine.dart';
import 'package:quantum_layout/src/plugins/quantum_api_engine.dart';
import 'package:quantum_layout/src/plugins/quantum_media_api.dart';

Future<Directory> _createTempDir(String prefix) {
  return Directory.systemTemp.createTemp(prefix);
}

Future<HttpServer> _bindServer(
  Future<void> Function(HttpRequest request) handle,
) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    try {
      await handle(request);
    } catch (e, st) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write('handler-error: $e');
      await request.response.close();
      Zone.current.handleUncaughtError(e, st);
    }
  });
  return server;
}

Uint8List _u8(List<int> values) => Uint8List.fromList(values);

class _SocketMediaHeaders implements MediaHttpHeaders {
  final Map<String, List<String>> _values = <String, List<String>>{};

  String _key(String name) => name.toLowerCase();

  @override
  void set(String name, Object value) {
    _values[_key(name)] = <String>[value.toString()];
  }

  @override
  void add(String name, Object value) {
    _values.putIfAbsent(_key(name), () => <String>[]).add(value.toString());
  }

  @override
  String? value(String name) {
    final values = _values[_key(name)];
    if (values == null || values.isEmpty) return null;
    return values.first;
  }

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _values.forEach(action);
  }

  Map<String, List<String>> toMap() => _values;
}

class _SocketMediaResponse implements MediaHttpResponse {
  final int _statusCode;
  final _SocketMediaHeaders _headers;
  final Stream<List<int>> _stream;

  _SocketMediaResponse(this._statusCode, this._headers, List<int> body)
      : _stream = Stream<List<int>>.value(body);

  @override
  int get statusCode => _statusCode;

  @override
  MediaHttpHeaders get headers => _headers;

  @override
  Stream<List<int>> get stream => _stream;
}

class _SocketMediaRequest implements MediaHttpRequest {
  final String method;
  final Uri uri;
  final _SocketMediaHeaders _headers = _SocketMediaHeaders();
  final BytesBuilder _body = BytesBuilder(copy: false);
  int _contentLength = 0;

  _SocketMediaRequest(this.method, this.uri);

  @override
  MediaHttpHeaders get headers => _headers;

  @override
  set contentLength(int value) {
    _contentLength = value;
  }

  @override
  void add(List<int> data) {
    _body.add(data);
  }

  List<int> _decodeChunked(List<int> body) {
    final output = BytesBuilder(copy: false);
    var index = 0;
    while (index < body.length) {
      var lineEnd = -1;
      for (var i = index; i + 1 < body.length; i++) {
        if (body[i] == 13 && body[i + 1] == 10) {
          lineEnd = i;
          break;
        }
      }
      if (lineEnd < 0) break;
      final sizeLine = ascii.decode(body.sublist(index, lineEnd)).trim();
      final size = int.parse(sizeLine, radix: 16);
      index = lineEnd + 2;
      if (size == 0) break;
      output.add(body.sublist(index, index + size));
      index += size + 2;
    }
    return output.takeBytes();
  }

  @override
  Future<MediaHttpResponse> close() async {
    final connectHost = uri.host == 'localhost' ? '127.0.0.1' : uri.host;
    final socket =
        await Socket.connect(connectHost, uri.port == 0 ? 80 : uri.port);
    final path = uri.hasQuery
        ? '${uri.path}?${uri.query}'
        : (uri.path.isEmpty ? '/' : uri.path);
    final body = _body.takeBytes();

    final requestLine = StringBuffer()
      ..write('$method $path HTTP/1.1\r\n')
      ..write('Host: ${uri.host}:${uri.port == 0 ? 80 : uri.port}\r\n')
      ..write('Connection: close\r\n');
    _headers.forEach((name, values) {
      for (final value in values) {
        requestLine.write('$name: $value\r\n');
      }
    });
    if (body.isNotEmpty || _contentLength > 0) {
      requestLine.write(
          'Content-Length: ${_contentLength > 0 ? _contentLength : body.length}\r\n');
    }
    requestLine.write('\r\n');

    socket.add(utf8.encode(requestLine.toString()));
    if (body.isNotEmpty) {
      socket.add(body);
    }
    await socket.flush();

    final responseBytes = <int>[];
    await for (final chunk in socket) {
      responseBytes.addAll(chunk);
    }
    socket.destroy();

    final separator = utf8.encode('\r\n\r\n');
    var splitIndex = -1;
    for (var i = 0; i <= responseBytes.length - separator.length; i++) {
      var matches = true;
      for (var j = 0; j < separator.length; j++) {
        if (responseBytes[i + j] != separator[j]) {
          matches = false;
          break;
        }
      }
      if (matches) {
        splitIndex = i;
        break;
      }
    }
    if (splitIndex < 0) {
      return _SocketMediaResponse(599, _SocketMediaHeaders(), responseBytes);
    }
    final headerBytes = responseBytes.sublist(0, splitIndex);
    var bodyBytes = responseBytes.sublist(splitIndex + 4);

    final headerText = utf8.decode(headerBytes);
    final lines = headerText.split('\r\n');
    final statusLine = lines.first;
    final statusMatch = RegExp(r'^HTTP/\d\.\d\s+(\d+)').firstMatch(statusLine);
    final statusCode =
        statusMatch == null ? 599 : int.parse(statusMatch.group(1)!);

    final headers = _SocketMediaHeaders();
    for (final line in lines.skip(1)) {
      final idx = line.indexOf(':');
      if (idx <= 0) continue;
      headers.add(
          line.substring(0, idx).trim(), line.substring(idx + 1).trim());
    }

    final transferEncoding = headers.value('transfer-encoding')?.toLowerCase();
    if (transferEncoding == 'chunked') {
      bodyBytes = _decodeChunked(bodyBytes);
    }

    return _SocketMediaResponse(statusCode, headers, bodyBytes);
  }
}

class _SocketMediaHttpClient implements MediaHttpClient {
  @override
  Future<MediaHttpRequest> getUrl(Uri uri) async =>
      _SocketMediaRequest('GET', uri);

  @override
  Future<MediaHttpRequest> postUrl(Uri uri) async =>
      _SocketMediaRequest('POST', uri);

  @override
  Future<MediaHttpRequest> putUrl(Uri uri) async =>
      _SocketMediaRequest('PUT', uri);

  @override
  Future<MediaHttpRequest> patchUrl(Uri uri) async =>
      _SocketMediaRequest('PATCH', uri);

  @override
  void close({bool force = false}) {}
}

void main() {
  late MediaHttpClientFactory previousFactory;

  setUpAll(() {
    previousFactory = mediaHttpClientFactory;
    mediaHttpClientFactory = () => _SocketMediaHttpClient();
  });

  tearDownAll(() {
    mediaHttpClientFactory = previousFactory;
  });

  group('media models and parsing', () {
    test('QLMediaPolicy presets keep feed and cinema defaults distinct', () {
      final feed = QLMediaPolicy.feed();
      final cinema = QLMediaPolicy.cinema();

      expect(feed.preloadAhead, 2);
      expect(feed.keepAliveBehind, 1);
      expect(cinema.preloadAhead, 0);
      expect(cinema.keepAliveBehind, 0);
    });

    test(
        'QLMediaSource classifies split, audio-only, and video-only topologies',
        () {
      const split = QLMediaSource(
        id: 'split',
        videoUrl: 'https://cdn.example.com/video.mp4',
        audioUrl: 'https://cdn.example.com/audio.m4a',
        thumbnailUrl: 'https://cdn.example.com/thumb.jpg',
        formatHint: QLStreamFormat.hls,
        httpHeaders: {'X-Token': 'alpha'},
        subtitleUrl: 'https://cdn.example.com/subtitles.srt',
        subtitleSyncOffsetMs: 250,
        loop: false,
        autoPlay: true,
      );
      const audioOnly = QLMediaSource(
        id: 'audio',
        audioUrl: 'https://cdn.example.com/audio.m4a',
      );
      const videoOnly = QLMediaSource(
        id: 'video',
        videoUrl: 'https://cdn.example.com/video.mp4',
      );

      expect(split.isSplitTrack, isTrue);
      expect(split.isAudioOnly, isFalse);
      expect(split.isVideoOnly, isFalse);
      expect(split.thumbnailUrl, 'https://cdn.example.com/thumb.jpg');
      expect(split.formatHint, QLStreamFormat.hls);
      expect(split.httpHeaders['X-Token'], 'alpha');
      expect(split.subtitleUrl, 'https://cdn.example.com/subtitles.srt');
      expect(split.subtitleSyncOffsetMs, 250);
      expect(split.loop, isFalse);
      expect(split.autoPlay, isTrue);

      expect(audioOnly.isAudioOnly, isTrue);
      expect(audioOnly.isVideoOnly, isFalse);
      expect(audioOnly.isSplitTrack, isFalse);

      expect(videoOnly.isVideoOnly, isTrue);
      expect(videoOnly.isAudioOnly, isFalse);
      expect(videoOnly.isSplitTrack, isFalse);
    });

    test('QLSubtitleTrack finds subtitle windows by binary search boundaries',
        () {
      final track = QLSubtitleTrack(
        Float64List.fromList(const [0, 1000, 1000, 2500, 2500, 4000]),
        const ['intro', 'middle', 'outro'],
      );

      expect(track.getActiveText(-1), isNull);
      expect(track.getActiveText(0), 'intro');
      expect(track.getActiveText(999), 'intro');
      expect(track.getActiveText(1000), 'middle');
      expect(track.getActiveText(2499), 'middle');
      expect(track.getActiveText(2500), 'outro');
      expect(track.getActiveText(3999), 'outro');
      expect(track.getActiveText(4000), isNull);
    });

    test(
        'QLSubtitleParser parses a remote SRT file and applies the sync offset',
        () async {
      final server = await _bindServer((request) async {
        request.response.headers.contentType =
            ContentType('text', 'plain', charset: 'utf-8');
        request.response.write(
            "1\n00:00:01,000 --> 00:00:02,000\nHello runtime\n\n2\n00:00:03,000 --> 00:00:04,500\nSecond line\n");
        await request.response.close();
      });
      addTearDown(() async => server.close(force: true));

      final url = 'http://127.0.0.1:${server.port}/subtitles.srt';
      final track = await QLSubtitleParser.parseNetwork(url, 500);

      expect(track, isNotNull);
      expect(track!.getActiveText(1499), isNull);
      expect(track.getActiveText(1500), 'Hello runtime');
      expect(track.getActiveText(2499), 'Hello runtime');
      expect(track.getActiveText(2500), isNull);
      expect(track.getActiveText(3500), 'Second line');
      expect(track.getActiveText(5000), isNull);
    });
  });

  group('cache, prefetch, and proxy', () {
    test(
        'MediaCacheManager evicts the oldest RAM entry when the budget is exceeded',
        () async {
      final dir = await _createTempDir('media-cache-ram-');
      final store = MemoryLocalStore();
      await store.init();
      addTearDown(() async => dir.delete(recursive: true));

      final cache = MediaCacheManager(
        cacheDir: dir,
        store: store,
        maxRamCacheBytes: 8,
      );
      await cache.init();

      await cache.saveToRam('https://cdn.example.com/a', _u8([1, 1, 1, 1, 1]));
      await cache.saveToRam('https://cdn.example.com/b', _u8([2, 2, 2, 2, 2]));

      expect(await cache.getFromRam('https://cdn.example.com/a'), isNull);
      expect(await cache.getFromRam('https://cdn.example.com/b'), isNotNull);
    });

    test('MediaCacheManager encrypts disk chunks and restores them losslessly',
        () async {
      final dir = await _createTempDir('media-cache-disk-');
      final store = MemoryLocalStore();
      await store.init();
      addTearDown(() async => dir.delete(recursive: true));

      final cache = MediaCacheManager(
        cacheDir: dir,
        store: store,
        clientSecret: 'top-secret',
      );
      await cache.init();

      final url = 'https://cdn.example.com/encrypted.mp4';
      final plain = _u8([10, 20, 30, 40, 50, 60, 70, 80]);

      await cache.saveChunkToDisk(url, 0, plain);

      final files = dir.listSync().whereType<File>().toList();
      expect(files, hasLength(1));
      final onDisk = await files.single.readAsBytes();
      expect(onDisk, isNot(equals(plain)));

      final restored = await cache.readChunkFromDisk(url, 0, plain.length - 1);
      expect(restored, plain);

      final tracker = await cache.getTracker(url);
      expect(tracker.hasRange(0, plain.length - 1), isTrue);
      expect(tracker.getMissingRanges(0, plain.length - 1), isEmpty);
    });

    test('MediaPrefetcher stores a successful partial fetch in cache',
        () async {
      final dir = await _createTempDir('media-prefetch-');
      final store = MemoryLocalStore();
      await store.init();
      addTearDown(() async => dir.delete(recursive: true));

      final cache = MediaCacheManager(cacheDir: dir, store: store);
      await cache.init();

      final requested = Completer<void>();
      final server = await _bindServer((request) async {
        expect(request.headers.value(HttpHeaders.rangeHeader), 'bytes=0-7');
        request.response.statusCode = HttpStatus.partialContent;
        request.response.headers.contentType =
            ContentType('application', 'octet-stream');
        request.response.add(_u8([0, 1, 2, 3, 4, 5, 6, 7]));
        await request.response.close();
        if (!requested.isCompleted) requested.complete();
      });
      addTearDown(() async => server.close(force: true));

      final resolvedUrl = 'http://127.0.0.1:${server.port}/range';
      final prefetcher = MediaPrefetcher(cache: cache);
      prefetcher.prefetch([resolvedUrl], bytesToFetch: 8);

      await requested.future.timeout(const Duration(seconds: 5));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final tracker = await cache.getTracker(resolvedUrl);
      expect(tracker.hasRange(0, 7), isTrue);
      final bytes = await cache.readChunkFromDisk(resolvedUrl, 0, 7);
      expect(bytes, _u8([0, 1, 2, 3, 4, 5, 6, 7]));
    });

    test(
        'MediaPrefetcher ignores a bad upstream response without corrupting the cache',
        () async {
      final dir = await _createTempDir('media-prefetch-bad-');
      final store = MemoryLocalStore();
      await store.init();
      addTearDown(() async => dir.delete(recursive: true));

      final cache = MediaCacheManager(cacheDir: dir, store: store);
      await cache.init();

      final requested = Completer<void>();
      final server = await _bindServer((request) async {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write('broken');
        await request.response.close();
        if (!requested.isCompleted) requested.complete();
      });
      addTearDown(() async => server.close(force: true));

      final url = 'http://127.0.0.1:${server.port}/broken';
      final prefetcher = MediaPrefetcher(cache: cache);
      prefetcher.prefetch([url], bytesToFetch: 8);

      await requested.future.timeout(const Duration(seconds: 5));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final tracker = await cache.getTracker(url);
      expect(tracker.hasRange(0, 7), isFalse);
      expect(dir.listSync().whereType<File>(), isEmpty);
    });

    test(
        'LocalMediaProxyServer blocks unauthorized requests and serves cached downloads for authorized ones',
        () async {
      final dir = await _createTempDir('media-proxy-');
      final store = MemoryLocalStore();
      await store.init();
      addTearDown(() async => dir.delete(recursive: true));

      final cache = MediaCacheManager(
        cacheDir: dir,
        store: store,
        clientSecret: 'proxy-secret',
      );
      await cache.init();

      final url = 'https://cdn.example.com/proxy-video.mp4';
      final plain = _u8([9, 8, 7, 6]);
      await cache.saveChunkToDisk(url, 0, plain);

      final proxy = LocalMediaProxyServer(cache: cache);
      await proxy.start();
      addTearDown(proxy.stop);

      final proxyUrl = proxy.getProxyUrl(url);
      expect(proxyUrl, contains('http://localhost:'));
      expect(proxyUrl, contains('/proxy?url='));

      final unauthorizedUri = Uri.parse(proxyUrl).replace(queryParameters: {
        'url': Uri.parse(proxyUrl).queryParameters['url']!,
      });

      final client = HttpClient();

      final unauthorizedReq = await client.getUrl(unauthorizedUri);
      final unauthorizedRes = await unauthorizedReq.close();
      expect(unauthorizedRes.statusCode, HttpStatus.forbidden);
      await unauthorizedRes.drain();

      final authorizedReq = await client.getUrl(Uri.parse(proxyUrl));
      authorizedReq.headers.set(HttpHeaders.rangeHeader, 'bytes=0-3');
      final authorizedRes = await authorizedReq.close();
      expect(authorizedRes.statusCode, HttpStatus.partialContent);
      final body =
          await authorizedRes.fold<BytesBuilder>(BytesBuilder(), (b, chunk) {
        b.add(chunk);
        return b;
      }).then((builder) => builder.takeBytes());
      expect(body, plain);

      client.close(force: true);
    });
  });

  group('stream quality, uploads, and live pipelines', () {
    test(
        'BandwidthEstimator maps throughput to the expected adaptive quality tier',
        () {
      final cases = <Map<String, Object>>[
        {'bytes': 2000000, 'expected': Quality.p4k},
        {'bytes': 1000000, 'expected': Quality.p1080},
        {'bytes': 400000, 'expected': Quality.p720},
        {'bytes': 200000, 'expected': Quality.p480},
        {'bytes': 100000, 'expected': Quality.p360},
        {'bytes': 50000, 'expected': Quality.p240},
      ];

      for (final entry in cases) {
        final estimator = BandwidthEstimator();
        estimator.addSample(entry['bytes'] as int, const Duration(seconds: 1));
        expect(estimator.getRecommendedQuality(), entry['expected']);
      }
    });

    test(
        'ResumableUploader sends a PATCH chunk with the expected headers and progress',
        () async {
      final dir = await _createTempDir('media-upload-');
      addTearDown(() async => dir.delete(recursive: true));

      final file = File('${dir.path}/upload.bin');
      await file.writeAsBytes(_u8([1, 2, 3, 4]));

      final requests = <HttpRequest>[];
      final server = await _bindServer((request) async {
        requests.add(request);
        expect(request.method, 'PATCH');
        expect(request.headers.value('Upload-Offset'), '0');
        expect(request.headers.value('Content-Range'), 'bytes 0-3/4');
        final body =
            await request.fold<BytesBuilder>(BytesBuilder(), (b, chunk) {
          b.add(chunk);
          return b;
        }).then((builder) => builder.takeBytes());
        expect(body, _u8([1, 2, 3, 4]));
        request.response.statusCode = HttpStatus.noContent;
        await request.response.close();
      });
      addTearDown(() async => server.close(force: true));

      final uploader = ResumableUploader(
        file: file,
        uploadUrl: 'http://127.0.0.1:${server.port}/upload',
        method: HttpMethod.patch,
        chunkSize: 4,
      );

      final progressEvents = <TransferProgress>[];
      final progressSub = uploader.progress.listen(progressEvents.add);
      await uploader.start();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await progressSub.cancel();

      expect(requests, hasLength(1));
      expect(progressEvents, isNotEmpty);
      final progress = progressEvents.last;
      expect(progress.sentBytes, 4);
      expect(progress.totalBytes, 4);
      expect(progress.progress, 1.0);
      expect(progress.stage, 'uploading');
    });

    test(
        'AdaptiveMediaStreamer switches quality after a fast first segment and streams the upgraded segment next',
        () async {
      final dir = await _createTempDir('media-abr-');
      final store = MemoryLocalStore();
      await store.init();
      addTearDown(() async => dir.delete(recursive: true));

      final cache = MediaCacheManager(cacheDir: dir, store: store);
      await cache.init();

      final requestedPaths = <String>[];
      final server = await _bindServer((request) async {
        requestedPaths.add(request.uri.path);
        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType =
            ContentType('application', 'octet-stream');
        request.response.add(utf8.encode(request.uri.path));
        await request.response.close();
      });
      addTearDown(() async => server.close(force: true));

      final base = 'http://127.0.0.1:${server.port}';
      final manifest = AdaptiveManifest(
        mediaId: 'reel-001',
        mediaType: MediaType.video,
        representations: {
          Quality.p240: [
            StreamSegment(
                sequenceNumber: 0,
                uri: '$base/p240/seg0',
                quality: Quality.p240),
            StreamSegment(
                sequenceNumber: 1,
                uri: '$base/p240/seg1',
                quality: Quality.p240),
          ],
          Quality.p4k: [
            StreamSegment(
                sequenceNumber: 0, uri: '$base/p4k/seg0', quality: Quality.p4k),
            StreamSegment(
                sequenceNumber: 1, uri: '$base/p4k/seg1', quality: Quality.p4k),
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
      final done = Completer<void>();
      final sub = streamer.stream.listen(
        emitted.add,
        onError: (Object e, StackTrace st) {
          if (!done.isCompleted) done.completeError(e, st);
        },
        onDone: () {
          if (!done.isCompleted) done.complete();
        },
      );

      streamer.start();

      final stopwatch = Stopwatch()..start();
      while (emitted.length < 2 &&
          stopwatch.elapsed < const Duration(seconds: 5)) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }

      expect(emitted, hasLength(2));
      streamer.stop();
      await done.future.timeout(const Duration(seconds: 5));
      await sub.cancel();

      expect(requestedPaths, hasLength(2));
      expect(requestedPaths.first, '/p240/seg0');
      expect(requestedPaths.last, '/p4k/seg1');
      expect(streamer.currentQuality, Quality.p4k);
    });

    test('AdaptiveMediaStreamer surfaces a fetch failure as a stream error',
        () async {
      final dir = await _createTempDir('media-abr-bad-');
      final store = MemoryLocalStore();
      await store.init();
      addTearDown(() async => dir.delete(recursive: true));

      final cache = MediaCacheManager(cacheDir: dir, store: store);
      await cache.init();

      final server = await _bindServer((request) async {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write('segment failed');
        await request.response.close();
      });
      addTearDown(() async => server.close(force: true));

      final manifest = AdaptiveManifest(
        mediaId: 'reel-bad',
        mediaType: MediaType.video,
        representations: {
          Quality.p240: [
            StreamSegment(
              sequenceNumber: 0,
              uri: 'http://127.0.0.1:${server.port}/bad-segment',
              quality: Quality.p240,
            ),
          ],
        },
      );

      final streamer = AdaptiveMediaStreamer(
        manifest: manifest,
        estimator: BandwidthEstimator(),
        cache: cache,
        initialQuality: Quality.p240,
      );

      final errors = <Object>[];
      final done = Completer<void>();
      final sub = streamer.stream.listen(
        (_) {},
        onError: (Object e, StackTrace st) {
          errors.add(e);
          if (!done.isCompleted) done.complete();
        },
      );

      streamer.start();
      await done.future.timeout(const Duration(seconds: 5));
      streamer.stop();
      await sub.cancel();

      expect(errors, hasLength(1));
      expect(errors.single, isA<VaultStreamException>());
      final err = errors.single as VaultStreamException;
      expect(err.code, 'segment_fetch_failed');
    });

    test(
        'LiveMediaPipeline serializes ingress frames and emits egress payloads',
        () async {
      final pipeline = LiveMediaPipeline();
      final inbound = StreamController<Uint8List>();
      addTearDown(() async {
        await inbound.close();
        pipeline.terminate();
      });

      final transmitted = Completer<Uint8List>();
      final received = Completer<Uint8List>();
      final errors = <Object>[];

      pipeline.initialize(
        transmitter: (Uint8List packet) async {
          if (!transmitted.isCompleted) transmitted.complete(packet);
        },
        sourceReceiver: inbound.stream,
      );

      final egressSub = pipeline.egressOutput.listen(
        (payload) {
          if (!received.isCompleted) received.complete(payload);
        },
        onError: errors.add,
      );
      addTearDown(egressSub.cancel);

      pipeline.ingressInput.add(_u8([9, 8, 7]));
      final serialized =
          await transmitted.future.timeout(const Duration(seconds: 5));
      expect(VoipPacket.deserialize(serialized).payload, _u8([9, 8, 7]));

      final incoming = VoipPacket(
        sequenceNumber: 7,
        timestamp: 123456,
        payloadType: 96,
        ssrc: pipeline.ssrc,
        payload: _u8([1, 2, 3, 4]),
      );
      inbound.add(incoming.serialize());

      final payload = await received.future.timeout(const Duration(seconds: 5));
      expect(payload, _u8([1, 2, 3, 4]));
      expect(errors, isEmpty);
    });

    test(
        'LiveMediaPipeline reports transmitter failures through the egress error channel',
        () async {
      final pipeline = LiveMediaPipeline();
      final inbound = StreamController<Uint8List>();
      addTearDown(() async {
        await inbound.close();
        pipeline.terminate();
      });

      final errors = <Object>[];
      final errorSeen = Completer<void>();
      final sub = pipeline.egressOutput.listen(
        (_) {},
        onError: (Object e, StackTrace st) {
          errors.add(e);
          if (!errorSeen.isCompleted) errorSeen.complete();
        },
      );
      addTearDown(sub.cancel);

      pipeline.initialize(
        transmitter: (Uint8List packet) async {
          throw StateError('boom');
        },
        sourceReceiver: inbound.stream,
      );

      pipeline.ingressInput.add(_u8([5, 4, 3]));
      await errorSeen.future.timeout(const Duration(seconds: 5));

      expect(errors, hasLength(1));
      expect(errors.single, isA<StateError>());
    });
  });

  group('widget surfaces and engine orchestration', () {
    testWidgets('QLVideoSurface shows the placeholder for audio-only sources',
        (tester) async {
      final controller = QLMediaPlaybackController(
        const QLMediaSource(
          id: 'audio-only',
          audioUrl: 'https://cdn.example.com/audio.mp3',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: QLVideoSurface(
            controller: controller,
            placeholder: const Text('audio placeholder'),
          ),
        ),
      );

      expect(find.text('audio placeholder'), findsOneWidget);
    });

    testWidgets(
        'QLVideoSurface shows the placeholder while a video source is still uninitialized',
        (tester) async {
      final controller = QLMediaPlaybackController(
        const QLMediaSource(
          id: 'video-source',
          videoUrl: 'https://cdn.example.com/video.mp4',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: QLVideoSurface(
            controller: controller,
            placeholder: const Text('loading video'),
          ),
        ),
      );

      expect(find.text('loading video'), findsOneWidget);
    });

    testWidgets('QLSubtitleOverlay rebuilds when the active subtitle changes',
        (tester) async {
      final controller = QLMediaPlaybackController(
        const QLMediaSource(
          id: 'subtitle-source',
          audioUrl: 'https://cdn.example.com/audio.mp3',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: QLSubtitleOverlay(controller: controller),
        ),
      );

      expect(find.text('caption'), findsNothing);

      controller.activeSubtitle.setSilent('caption');
      controller.activeSubtitle.forceNotify();
      await tester.pump();

      expect(find.text('caption'), findsOneWidget);
    });

    test(
        'QuantumMediaEngine deduplicates concurrent downloads and preserves hot-cache reads',
        () async {
      final dir = await _createTempDir('quantum-media-engine-');
      final store = MemoryLocalStore();
      await store.init();
      addTearDown(() async => dir.delete(recursive: true));

      final requestCount = ValueNotifier<int>(0);
      final server = await _bindServer((request) async {
        requestCount.value += 1;
        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType =
            ContentType('application', 'octet-stream');
        request.response.add(_u8([11, 22, 33, 44]));
        await request.response.close();
      });
      addTearDown(() async => server.close(force: true));

      final engine = QuantumMediaEngine.instance;
      await engine.init(
          localStore: store,
          cacheDirectory: dir,
          clientSecret: 'engine-secret');

      final url = 'http://127.0.0.1:${server.port}/asset.bin';
      final first = engine.getMediaBytes(url);
      final second = engine.getMediaBytes(url);
      final results = await Future.wait([first, second]);

      expect(results[0], _u8([11, 22, 33, 44]));
      expect(results[1], _u8([11, 22, 33, 44]));
      expect(requestCount.value, 1);

      final third = await engine.getMediaBytes(url);
      expect(third, _u8([11, 22, 33, 44]));
      expect(requestCount.value, 1);

      final proxyUrl = engine.getProxyPlayUrl(url);
      expect(proxyUrl, contains('http://localhost:'));

      await engine.dispose();
    });
  });

  group('media durability and edge cases', () {
    test(
        'MediaCacheManager evicts the least recently used RAM entry under pressure',
        () async {
      final dir = await _createTempDir('media-ram-eviction-');
      final store = MemoryLocalStore();
      await store.init();
      addTearDown(() async => dir.delete(recursive: true));

      final cache = MediaCacheManager(
        cacheDir: dir,
        store: store,
        maxRamCacheBytes: 6,
      );
      await cache.init();

      final a = _u8([1, 1, 1]);
      final b = _u8([2, 2, 2]);
      final c = _u8([3, 3, 3]);

      await cache.saveToRam('https://cdn.example.com/a', a);
      await cache.saveToRam('https://cdn.example.com/b', b);
      expect(await cache.getFromRam('https://cdn.example.com/a'), a);

      await cache.saveToRam('https://cdn.example.com/c', c);

      expect(await cache.getFromRam('https://cdn.example.com/a'), isNotNull);
      expect(await cache.getFromRam('https://cdn.example.com/c'), isNotNull);
      expect(await cache.getFromRam('https://cdn.example.com/b'), isNull);
    });

    test('MediaCacheManager decrypts disk chunks after an encrypted round trip',
        () async {
      final dir = await _createTempDir('media-encrypted-disk-');
      final store = MemoryLocalStore();
      await store.init();
      addTearDown(() async => dir.delete(recursive: true));

      final cache = MediaCacheManager(
        cacheDir: dir,
        store: store,
        clientSecret: 'disk-secret',
      );
      await cache.init();

      final url = 'https://cdn.example.com/encrypted.bin';
      final bytes = _u8([10, 20, 30, 40, 50, 60]);
      await cache.saveChunkToDisk(url, 0, bytes);

      final tracker = await cache.getTracker(url);
      expect(tracker.hasRange(0, 5), isTrue);

      final restored = await cache.readChunkFromDisk(url, 0, 5);
      expect(restored, bytes);
    });

    test(
        'LocalMediaProxyServer returns 206 and exact content for a cached range request',
        () async {
      final dir = await _createTempDir('media-proxy-range-');
      final store = MemoryLocalStore();
      await store.init();
      addTearDown(() async => dir.delete(recursive: true));

      final cache = MediaCacheManager(
        cacheDir: dir,
        store: store,
        clientSecret: 'range-secret',
      );
      await cache.init();

      final upstreamHit = Completer<void>();
      final upstream = await _bindServer((request) async {
        if (!upstreamHit.isCompleted) upstreamHit.complete();
        request.response.statusCode = HttpStatus.ok;
        request.response.write('should-not-happen');
        await request.response.close();
      });
      addTearDown(() async => upstream.close(force: true));

      final url = 'https://cdn.example.com/cached-range.mp4';
      final bytes = _u8([7, 8, 9, 10, 11, 12]);
      await cache.saveChunkToDisk(url, 0, bytes);

      final proxy = LocalMediaProxyServer(cache: cache);
      await proxy.start();
      addTearDown(proxy.stop);

      final client = _SocketMediaHttpClient();
      final req = await client.getUrl(Uri.parse(proxy.getProxyUrl(url)));
      req.headers.set(HttpHeaders.rangeHeader, 'bytes=0-5');
      final res = await req.close();
      expect(res.statusCode, HttpStatus.partialContent);
      final body =
          await res.stream.fold<BytesBuilder>(BytesBuilder(), (builder, chunk) {
        builder.add(chunk);
        return builder;
      }).then((builder) => builder.takeBytes());
      expect(body, bytes);
      // expect(
      //     await upstreamHit.future.timeout(const Duration(milliseconds: 100),
      //         onTimeout: () => null),
      //     isNull);
    });

    test(
        'LiveMediaPipeline reports malformed packet payloads through the error channel',
        () async {
      final pipeline = LiveMediaPipeline();
      final inbound = StreamController<Uint8List>();
      addTearDown(() async {
        await inbound.close();
        pipeline.terminate();
      });

      final errors = <Object>[];
      final errorSeen = Completer<void>();
      final sub = pipeline.egressOutput.listen(
        (_) {},
        onError: (Object e, StackTrace st) {
          errors.add(e);
          if (!errorSeen.isCompleted) errorSeen.complete();
        },
      );
      addTearDown(sub.cancel);

      pipeline.initialize(
        transmitter: (Uint8List packet) async {},
        sourceReceiver: inbound.stream,
      );

      inbound.add(_u8([1, 2, 3, 4, 5]));
      await errorSeen.future.timeout(const Duration(seconds: 5));

      expect(errors, hasLength(1));
      expect(errors.single, isA<VaultStreamException>());
      final err = errors.single as VaultStreamException;
      expect(err.code, 'voip_corrupt');
    });
  });
}
