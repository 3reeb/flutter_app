import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/src/features/media/quantum_media_engine.dart';
import 'package:quantum_layout/src/plugins/quantum_api_engine.dart';
import 'package:quantum_layout/src/plugins/quantum_media_api.dart';

Future<Directory> _tempDir(String prefix) =>
    Directory.systemTemp.createTemp(prefix);
// AFTER (THE FIX):
Future<HttpServer> _server(
    Future<void> Function(HttpRequest request) handler) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    try {
      await handler(request);
    } catch (e, st) {
      try {
        // 👈 Replaced the if-statement with a try/catch
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write('handler-error: $e');
        await request.response.close();
      } catch (_) {
        // Ignore StateError if headers/response were already sent
      }
      Zone.current.handleUncaughtError(e, st);
    }
  });
  return server;
}

Uint8List _bytes(List<int> values) => Uint8List.fromList(values);

class _SocketHeaders implements MediaHttpHeaders {
  final Map<String, List<String>> _values = <String, List<String>>{};

  String _k(String name) => name.toLowerCase();

  @override
  void set(String name, Object value) {
    _values[_k(name)] = <String>[value.toString()];
  }

  @override
  void add(String name, Object value) {
    _values.putIfAbsent(_k(name), () => <String>[]).add(value.toString());
  }

  @override
  String? value(String name) {
    final list = _values[_k(name)];
    if (list == null || list.isEmpty) return null;
    return list.first;
  }

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _values.forEach(action);
  }
}

class _SocketResponse implements MediaHttpResponse {
  final int _statusCode;
  final _SocketHeaders _headers;
  final Stream<List<int>> _stream;

  _SocketResponse(this._statusCode, this._headers, List<int> body)
      : _stream = Stream<List<int>>.value(body);

  @override
  int get statusCode => _statusCode;

  @override
  MediaHttpHeaders get headers => _headers;

  @override
  Stream<List<int>> get stream => _stream;
}

class _SocketRequest implements MediaHttpRequest {
  final String method;
  final Uri uri;
  final _SocketHeaders _headers = _SocketHeaders();
  final BytesBuilder _body = BytesBuilder(copy: false);
  int _contentLength = 0;

  _SocketRequest(this.method, this.uri);

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
    final host = uri.host == 'localhost' ? '127.0.0.1' : uri.host;
    final port = uri.port == 0 ? 80 : uri.port;
    final socket = await Socket.connect(host, port);

    final path = uri.hasQuery
        ? '${uri.path}?${uri.query}'
        : (uri.path.isEmpty ? '/' : uri.path);
    final body = _body.takeBytes();

    final requestLine = StringBuffer()
      ..write('$method $path HTTP/1.1\r\n')
      ..write('Host: ${uri.host}:$port\r\n')
      ..write('Connection: close\r\n');

    _headers.forEach((name, values) {
      for (final value in values) {
        requestLine.write('$name: $value\r\n');
      }
    });

    if (body.isNotEmpty || _contentLength > 0 || method != 'GET') {
      requestLine.write(
          'Content-Length: ${_contentLength > 0 ? _contentLength : body.length}\r\n');
    }
    requestLine.write('\r\n');

    socket.add(utf8.encode(requestLine.toString()));
    if (body.isNotEmpty) socket.add(body);
    await socket.flush();
    try {
      await socket.close();
    } catch (_) {}

    final responseBytes = <int>[];
    await for (final chunk in socket) {
      responseBytes.addAll(chunk);
    }
    socket.destroy();

    final separator = utf8.encode('\r\n\r\n');
    var splitIndex = -1;
    for (var i = 0; i <= responseBytes.length - separator.length; i++) {
      var match = true;
      for (var j = 0; j < separator.length; j++) {
        if (responseBytes[i + j] != separator[j]) {
          match = false;
          break;
        }
      }
      if (match) {
        splitIndex = i;
        break;
      }
    }
    if (splitIndex < 0) {
      return _SocketResponse(599, _SocketHeaders(), responseBytes);
    }

    final headerBytes = responseBytes.sublist(0, splitIndex);
    var bodyBytes = responseBytes.sublist(splitIndex + 4);

    final headerText = utf8.decode(headerBytes, allowMalformed: true);
    final lines = headerText.split('\r\n');
    final statusMatch = RegExp(r'^HTTP/\d\.\d\s+(\d+)').firstMatch(lines.first);
    final statusCode =
        statusMatch == null ? 599 : int.parse(statusMatch.group(1)!);

    final headers = _SocketHeaders();
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

    return _SocketResponse(statusCode, headers, bodyBytes);
  }
}

class _SocketClient implements MediaHttpClient {
  @override
  Future<MediaHttpRequest> getUrl(Uri uri) async => _SocketRequest('GET', uri);

  @override
  Future<MediaHttpRequest> postUrl(Uri uri) async =>
      _SocketRequest('POST', uri);

  @override
  Future<MediaHttpRequest> putUrl(Uri uri) async => _SocketRequest('PUT', uri);

  @override
  Future<MediaHttpRequest> patchUrl(Uri uri) async =>
      _SocketRequest('PATCH', uri);

  @override
  void close({bool force = false}) {}
}

void main() {
  late MediaHttpClientFactory previousFactory;

  setUpAll(() {
    previousFactory = mediaHttpClientFactory;
    mediaHttpClientFactory = () => _SocketClient();
  });

  tearDownAll(() {
    mediaHttpClientFactory = previousFactory;
  });

  group('subtitle parsing', () {
    test('parses multiline remote SRT blocks and applies the offset', () async {
      final server = await _server((request) async {
        request.response.headers.contentType =
            ContentType('text', 'plain', charset: 'utf-8');
        request.response.write(
          '1\n'
          '00:00:01,000 --> 00:00:02,000\n'
          'Hello runtime\n'
          'from line two\n\n'
          '2\n'
          '00:00:04,000 --> 00:00:05,000\n'
          'Second block\n',
        );
        await request.response.close();
      });
      addTearDown(() async => server.close(force: true));

      final track = await QLSubtitleParser.parseNetwork(
        'http://127.0.0.1:${server.port}/subtitles.srt',
        250,
        // client: _SocketClient(),
      );

      expect(track, isNotNull);
      expect(track!.getActiveText(1249), isNull);
      expect(track.getActiveText(1250), 'Hello runtime\nfrom line two');
      expect(track.getActiveText(2249), 'Hello runtime\nfrom line two');
      expect(track.getActiveText(2250), isNull);
      expect(track.getActiveText(4250), 'Second block');
      expect(track.getActiveText(5250), isNull);
    });

    test('returns null for non-SRT payloads', () async {
      final server = await _server((request) async {
        request.response.headers.contentType =
            ContentType('text', 'plain', charset: 'utf-8');
        request.response.write('not subtitle data');
        await request.response.close();
      });
      addTearDown(() async => server.close(force: true));

      final track = await QLSubtitleParser.parseNetwork(
        'http://127.0.0.1:${server.port}/garbage.txt',
        0,
        // client: _SocketClient(),
      );

      expect(track, isNull);
    });
  });

  group('cache, proxy, and prefetch', () {
    test('merges adjacent cached ranges and persists them through the store',
        () async {
      final dir = await _tempDir('media-cache-ranges-');
      final store = MemoryLocalStore();
      await store.init();
      addTearDown(() async => dir.delete(recursive: true));

      final cache = MediaCacheManager(cacheDir: dir, store: store);
      await cache.init();

      final url = 'https://cdn.example.com/video.bin';
      await cache.saveChunkToDisk(url, 0, _bytes([1, 2, 3, 4]));
      await cache.saveChunkToDisk(url, 4, _bytes([5, 6, 7, 8]));

      final tracker = await cache.getTracker(url);
      expect(tracker.hasRange(0, 7), isTrue);
      expect(tracker.getMissingRanges(0, 7), isEmpty);

      final secondCache = MediaCacheManager(cacheDir: dir, store: store);
      await secondCache.init();
      final restoredTracker = await secondCache.getTracker(url);
      expect(restoredTracker.hasRange(0, 7), isTrue);
      expect(restoredTracker.getMissingRanges(0, 7), isEmpty);
    });

    test(
        'prefetcher deduplicates duplicate requests and caches the fetched range',
        () async {
      final dir = await _tempDir('media-prefetch-dedup-');
      final store = MemoryLocalStore();
      await store.init();
      addTearDown(() async => dir.delete(recursive: true));

      final cache = MediaCacheManager(cacheDir: dir, store: store);
      await cache.init();

      var requestCount = 0;
      final server = await _server((request) async {
        requestCount += 1;
        expect(request.headers.value(HttpHeaders.rangeHeader), 'bytes=0-7');
        request.response.statusCode = HttpStatus.partialContent;
        request.response.headers.contentType =
            ContentType('application', 'octet-stream');
        request.response.add(_bytes([0, 1, 2, 3, 4, 5, 6, 7]));
        await request.response.close();
      });
      addTearDown(() async => server.close(force: true));

      final url = 'http://127.0.0.1:${server.port}/range';
      final prefetcher = MediaPrefetcher(cache: cache);
      prefetcher.prefetch([url, url], bytesToFetch: 8);

      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(requestCount, 1);

      final tracker = await cache.getTracker(url);
      expect(tracker.hasRange(0, 7), isTrue);
      final bytes = await cache.readChunkFromDisk(url, 0, 7);
      expect(bytes, _bytes([0, 1, 2, 3, 4, 5, 6, 7]));
    });

    test('prefetcher ignores a bad upstream response and keeps the cache empty',
        () async {
      final dir = await _tempDir('media-prefetch-failure-');
      final store = MemoryLocalStore();
      await store.init();
      addTearDown(() async => dir.delete(recursive: true));

      final cache = MediaCacheManager(cacheDir: dir, store: store);
      await cache.init();

      var requestCount = 0;
      final server = await _server((request) async {
        requestCount += 1;
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write('broken');
        await request.response.close();
      });
      addTearDown(() async => server.close(force: true));

      final url = 'http://127.0.0.1:${server.port}/broken';
      final prefetcher = MediaPrefetcher(cache: cache);
      prefetcher.prefetch([url], bytesToFetch: 8);

      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(requestCount, 1);

      final tracker = await cache.getTracker(url);
      expect(tracker.hasRange(0, 7), isFalse);
      expect(dir.listSync().whereType<File>(), isEmpty);
    });

    test(
        'proxy rejects unauthorized requests and serves cached bytes for valid ones',
        () async {
      final dir = await _tempDir('media-proxy-cache-');
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
      await cache.saveChunkToDisk(url, 0, _bytes([9, 8, 7, 6]));

      final proxy = LocalMediaProxyServer(cache: cache);
      await proxy.start();
      addTearDown(proxy.stop);

      final proxyUrl = proxy.getProxyUrl(url);
      final unauthorized = Uri.parse(proxyUrl).replace(queryParameters: {
        'url': Uri.parse(proxyUrl).queryParameters['url']!,
      });

      final client = _SocketClient();

      final unauthorizedReq = await client.getUrl(unauthorized);
      final unauthorizedRes = await unauthorizedReq.close();
      expect(unauthorizedRes.statusCode, HttpStatus.forbidden);
      await unauthorizedRes.stream.drain();

      final authorizedReq = await client.getUrl(Uri.parse(proxyUrl));
      authorizedReq.headers.set(HttpHeaders.rangeHeader, 'bytes=0-3');
      final authorizedRes = await authorizedReq.close();
      expect(authorizedRes.statusCode, HttpStatus.partialContent);
      final body = await authorizedRes.stream.fold<BytesBuilder>(BytesBuilder(),
          (b, chunk) {
        b.add(chunk);
        return b;
      }).then((builder) => builder.takeBytes());
      expect(body, _bytes([9, 8, 7, 6]));
    });

    test('proxy fetches from upstream once and then serves the cache',
        () async {
      final dir = await _tempDir('media-proxy-upstream-');
      final store = MemoryLocalStore();
      await store.init();
      addTearDown(() async => dir.delete(recursive: true));

      final cache = MediaCacheManager(
        cacheDir: dir,
        store: store,
        clientSecret: 'proxy-secret',
      );
      await cache.init();

      var upstreamRequests = 0;
      final upstream = await _server((request) async {
        upstreamRequests += 1;
        expect(request.headers.value(HttpHeaders.rangeHeader), 'bytes=0-3');
        request.response.statusCode = HttpStatus.partialContent;
        request.response.headers.add(
          HttpHeaders.contentRangeHeader,
          'bytes 0-3/4',
        );
        request.response.headers.contentType =
            ContentType('application', 'octet-stream');
        request.response.contentLength = 4;
        request.response.add(_bytes([1, 2, 3, 4]));
        await request.response.close();
      });
      addTearDown(() async => upstream.close(force: true));

      final url = 'http://127.0.0.1:${upstream.port}/asset.bin';
      final proxy = LocalMediaProxyServer(cache: cache);
      await proxy.start();
      addTearDown(proxy.stop);

      final client = _SocketClient();
      final proxyUrl = proxy.getProxyUrl(url);

      Future<Uint8List> fetchOnce() async {
        final req = await client.getUrl(Uri.parse(proxyUrl));
        req.headers.set(HttpHeaders.rangeHeader, 'bytes=0-3');
        final res = await req.close();
        expect(res.statusCode, HttpStatus.partialContent);
        return res.stream.fold<BytesBuilder>(BytesBuilder(), (b, chunk) {
          b.add(chunk);
          return b;
        }).then((builder) => builder.takeBytes());
      }

      final first = await fetchOnce();
      final second = await fetchOnce();

      expect(first, _bytes([1, 2, 3, 4]));
      expect(second, _bytes([1, 2, 3, 4]));
      expect(upstreamRequests, 1);
    });
  });

  group('uploads, streams, and live audio/video', () {
    test('ResumableUploader retries a transient 500 and eventually succeeds',
        () async {
      final dir = await _tempDir('media-upload-retry-');
      addTearDown(() async => dir.delete(recursive: true));

      final file = File('${dir.path}/upload.bin');
      await file.writeAsBytes(_bytes([1, 2, 3, 4]));

      var requestCount = 0;
      final server = await _server((request) async {
        requestCount += 1;
        expect(request.method, 'PATCH');
        expect(request.headers.value('Upload-Offset'), '0');
        expect(request.headers.value('Content-Range'), 'bytes 0-3/4');
        final body =
            await request.fold<BytesBuilder>(BytesBuilder(), (b, chunk) {
          b.add(chunk);
          return b;
        }).then((builder) => builder.takeBytes());
        expect(body, _bytes([1, 2, 3, 4]));

        if (requestCount == 1) {
          request.response.statusCode = HttpStatus.internalServerError;
        } else {
          request.response.statusCode = HttpStatus.noContent;
        }
        await request.response.close();
      });
      addTearDown(() async => server.close(force: true));

      final uploader = ResumableUploader(
        file: file,
        uploadUrl: 'http://127.0.0.1:${server.port}/upload',
        method: HttpMethod.patch,
        chunkSize: 4,
      );

      final progress = <TransferProgress>[];
      final sub = uploader.progress.listen(progress.add);
      await uploader.start();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await sub.cancel();

      expect(requestCount, 2);
      expect(progress, isNotEmpty);
      expect(progress.last.sentBytes, 4);
      expect(progress.last.totalBytes, 4);
      expect(progress.last.progress, 1.0);
    });

    test('ResumableUploader resumes from a non-zero offset', () async {
      final dir = await _tempDir('media-upload-resume-');
      addTearDown(() async => dir.delete(recursive: true));

      final file = File('${dir.path}/resume.bin');
      await file.writeAsBytes(_bytes([1, 2, 3, 4, 5, 6, 7, 8]));

      final observed = Completer<void>();
      final server = await _server((request) async {
        expect(request.method, 'PATCH');
        expect(request.headers.value('Upload-Offset'), '4');
        expect(request.headers.value('Content-Range'), 'bytes 4-7/8');
        final body =
            await request.fold<BytesBuilder>(BytesBuilder(), (b, chunk) {
          b.add(chunk);
          return b;
        }).then((builder) => builder.takeBytes());
        expect(body, _bytes([5, 6, 7, 8]));
        request.response.statusCode = HttpStatus.noContent;
        await request.response.close();
        if (!observed.isCompleted) observed.complete();
      });
      addTearDown(() async => server.close(force: true));

      final uploader = ResumableUploader(
        file: file,
        uploadUrl: 'http://127.0.0.1:${server.port}/resume',
        method: HttpMethod.patch,
        chunkSize: 4,
      );

      final events = <TransferProgress>[];
      final sub = uploader.progress.listen(events.add);
      await uploader.start(startOffset: 4);
      await observed.future.timeout(const Duration(seconds: 5));
      await sub.cancel();

      expect(events, isNotEmpty);
      expect(events.last.sentBytes, 8);
      expect(events.last.totalBytes, 8);
      expect(events.last.progress, 1.0);
    });

    test(
        'AdaptiveMediaStreamer upgrades to the next quality after a fast first segment',
        () async {
      final dir = await _tempDir('media-abr-upgrade-');
      final store = MemoryLocalStore();
      await store.init();
      addTearDown(() async => dir.delete(recursive: true));

      final cache = MediaCacheManager(cacheDir: dir, store: store);
      await cache.init();

      final requestedPaths = <String>[];
      final server = await _server((request) async {
        requestedPaths.add(request.uri.path);
        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType =
            ContentType('application', 'octet-stream');
        if (request.uri.path == '/p240/seg0') {
          request.response.add(List<int>.filled(512 * 1024, 1));
        } else {
          request.response.add(utf8.encode(request.uri.path));
        }
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
        onError: (Object error, StackTrace stackTrace) {
          if (!done.isCompleted) done.completeError(error, stackTrace);
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

    test(
        'AdaptiveMediaStreamer reads a disk-hot segment without contacting upstream',
        () async {
      final dir = await _tempDir('media-abr-cache-');
      final store = MemoryLocalStore();
      await store.init();
      addTearDown(() async => dir.delete(recursive: true));

      final cache = MediaCacheManager(cacheDir: dir, store: store);
      await cache.init();

      var upstreamRequests = 0;
      final server = await _server((request) async {
        upstreamRequests += 1;
        request.response.statusCode = HttpStatus.ok;
        request.response.add(utf8.encode('should not be used'));
        await request.response.close();
      });
      addTearDown(() async => server.close(force: true));

      final url = 'http://127.0.0.1:${server.port}/cached/seg0';
      final bytes = _bytes([10, 11, 12, 13, 14, 15]);
      await cache.saveChunkToDisk(url, 0, bytes);

      final manifest = AdaptiveManifest(
        mediaId: 'reel-cache',
        mediaType: MediaType.video,
        representations: {
          Quality.p240: [
            StreamSegment(sequenceNumber: 0, uri: url, quality: Quality.p240),
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
        onError: (Object error, StackTrace stackTrace) {
          if (!done.isCompleted) done.completeError(error, stackTrace);
        },
        onDone: () {
          if (!done.isCompleted) done.complete();
        },
      );

      streamer.start();
      await done.future.timeout(const Duration(seconds: 5));
      await sub.cancel();

      expect(emitted, hasLength(1));
      expect(emitted.single, bytes);
      expect(upstreamRequests, 0);
    });

    test(
        'LiveMediaPipeline preserves packet ordering and payloads in both directions',
        () async {
      final pipeline = LiveMediaPipeline();
      final inbound = StreamController<Uint8List>();
      addTearDown(() async {
        await inbound.close();
        pipeline.terminate();
      });

      final transmitted = <VoipPacket>[];
      final received = <Uint8List>[];
      final completed = Completer<void>();

      pipeline.initialize(
        transmitter: (Uint8List packet) async {
          transmitted.add(VoipPacket.deserialize(packet));
        },
        sourceReceiver: inbound.stream,
      );

      final egressSub = pipeline.egressOutput.listen((payload) {
        received.add(payload);
        if (received.length == 2 && !completed.isCompleted) {
          completed.complete();
        }
      });
      addTearDown(egressSub.cancel);

      pipeline.ingressInput.add(_bytes([1, 2, 3]));
      pipeline.ingressInput.add(_bytes([4, 5, 6]));

      inbound.add(VoipPacket(
        sequenceNumber: 100,
        timestamp: 111,
        payloadType: 96,
        ssrc: pipeline.ssrc,
        payload: _bytes([9, 9]),
      ).serialize());
      inbound.add(VoipPacket(
        sequenceNumber: 101,
        timestamp: 222,
        payloadType: 96,
        ssrc: pipeline.ssrc,
        payload: _bytes([8, 8, 8]),
      ).serialize());

      await completed.future.timeout(const Duration(seconds: 5));

      expect(transmitted, hasLength(2));
      expect(transmitted[0].sequenceNumber, 0);
      expect(transmitted[1].sequenceNumber, 1);
      expect(received, [
        _bytes([9, 9]),
        _bytes([8, 8, 8])
      ]);
    });
  });

  group('widget surfaces', () {
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
  });

  group('media durability matrix', () {
    test(
        'MediaCacheManager keeps the newest RAM entries after eviction pressure',
        () async {
      final dir = await _tempDir('media-matrix-ram-');
      final store = MemoryLocalStore();
      await store.init();
      addTearDown(() async => dir.delete(recursive: true));

      final cache = MediaCacheManager(
        cacheDir: dir,
        store: store,
        maxRamCacheBytes: 5,
      );
      await cache.init();

      await cache.saveToRam('https://cdn.example.com/first', _bytes([1, 1, 1]));
      await cache.saveToRam(
          'https://cdn.example.com/second', _bytes([2, 2, 2]));
      expect(
          await cache.getFromRam('https://cdn.example.com/first'), isNotNull);

      await cache.saveToRam('https://cdn.example.com/third', _bytes([3, 3, 3]));
      expect(await cache.getFromRam('https://cdn.example.com/second'), isNull);
      expect(
          await cache.getFromRam('https://cdn.example.com/third'), isNotNull);
    });

    test(
        'BandwidthEstimator transitions quality tiers across slow and fast samples',
        () {
      final estimator = BandwidthEstimator();
      estimator.addSample(64 * 1024, const Duration(seconds: 2));
      expect(estimator.getRecommendedQuality(), Quality.p240);

      estimator.addSample(2 * 1024 * 1024, const Duration(milliseconds: 250));
      expect(estimator.getRecommendedQuality(),
          anyOf(Quality.p1080, Quality.p4k, Quality.p720));
    });

    test('VoipPacket serializes and deserializes live payloads losslessly', () {
      final packet = VoipPacket(
        sequenceNumber: 42,
        timestamp: 987654321,
        payloadType: 96,
        ssrc: 123456,
        payload: _bytes([9, 8, 7, 6]),
      );

      final decoded = VoipPacket.deserialize(packet.serialize());
      expect(decoded.sequenceNumber, 42);
      expect(decoded.timestamp, 987654321);
      expect(decoded.payloadType, 96);
      expect(decoded.ssrc, 123456);
      expect(decoded.payload, _bytes([9, 8, 7, 6]));
    });

    test(
        'AdaptiveMediaStreamer closes the stream after a disk-hot segment completes',
        () async {
      final dir = await _tempDir('media-matrix-hot-');
      final store = MemoryLocalStore();
      await store.init();
      addTearDown(() async => dir.delete(recursive: true));

      final cache = MediaCacheManager(cacheDir: dir, store: store);
      await cache.init();

      final server = await _server((request) async {
        request.response.statusCode = HttpStatus.ok;
        request.response.write('should not be requested');
        await request.response.close();
      });
      addTearDown(() async => server.close(force: true));

      final url = 'http://127.0.0.1:${server.port}/hot/seg0';
      final bytes = _bytes([10, 11, 12, 13, 14, 15]);
      await cache.saveChunkToDisk(url, 0, bytes);

      final manifest = AdaptiveManifest(
        mediaId: 'hot-reel',
        mediaType: MediaType.video,
        representations: {
          Quality.p240: [
            StreamSegment(sequenceNumber: 0, uri: url, quality: Quality.p240),
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
        onDone: () {
          if (!done.isCompleted) done.complete();
        },
        onError: (Object e, StackTrace st) {
          if (!done.isCompleted) done.completeError(e, st);
        },
      );

      streamer.start();
      await done.future.timeout(const Duration(seconds: 5));
      await sub.cancel();

      expect(emitted, hasLength(1));
      expect(emitted.single, bytes);
    });
  });
}
