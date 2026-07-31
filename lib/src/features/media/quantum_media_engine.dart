import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

// Ecosystem Primitives
import '../../foundation/quantum_primitives.dart';
import '../../foundation/quantum_async.dart';
import 'package:quantum_layout/quantum.dart';

// 🚀 TRUE PRODUCTION CORE IMPORT
import 'package:quantum_layout/src/runtime/api/network_shell.dart';

// ─────────────────────────────────────────────────────────────────────── §1 ─
//  FRONTEND POLICIES & MODELS
// ────────────────────────────────────────────────────────────────────────────

enum QLStreamFormat { auto, hls, dash, ss, other }

@immutable
class QLMediaPolicy {
  final int preloadAhead;
  final int keepAliveBehind;
  const QLMediaPolicy({this.preloadAhead = 2, this.keepAliveBehind = 1});
  factory QLMediaPolicy.feed() =>
      const QLMediaPolicy(preloadAhead: 2, keepAliveBehind: 1);
  factory QLMediaPolicy.cinema() =>
      const QLMediaPolicy(preloadAhead: 0, keepAliveBehind: 0);
}

class QLMediaSource {
  final String id;
  final String? videoUrl;
  final String? audioUrl;
  final String? thumbnailUrl;
  final QLStreamFormat formatHint;
  final Map<String, String> httpHeaders;
  final String? subtitleUrl;
  final int subtitleSyncOffsetMs;
  final bool loop;
  final bool autoPlay;

  const QLMediaSource({
    required this.id,
    this.videoUrl,
    this.audioUrl,
    this.thumbnailUrl,
    this.formatHint = QLStreamFormat.auto,
    this.httpHeaders = const {},
    this.subtitleUrl,
    this.subtitleSyncOffsetMs = 0,
    this.loop = true,
    this.autoPlay = false,
  });

  bool get isSplitTrack => videoUrl != null && audioUrl != null;
  bool get isAudioOnly => videoUrl == null && audioUrl != null;
  bool get isVideoOnly => videoUrl != null && audioUrl == null;
}

// ─────────────────────────────────────────────────────────────────────── §2 ─
//  SUBTITLE ENGINE (O(log N) Binary Search)
// ────────────────────────────────────────────────────────────────────────────

class QLSubtitleTrack {
  final Float64List timings;
  final List<String> texts;
  QLSubtitleTrack(this.timings, this.texts);

  String? getActiveText(int positionMs) {
    if (timings.isEmpty) return null;
    int low = 0, high = (timings.length ~/ 2) - 1;
    while (low <= high) {
      final int mid = (low + high) ~/ 2;
      final int start = timings[mid * 2].toInt();
      final int end = timings[mid * 2 + 1].toInt();
      if (positionMs >= start && positionMs < end)
        return texts[mid];
      else if (positionMs < start)
        high = mid - 1;
      else
        low = mid + 1;
    }
    return null;
  }
}

abstract final class QLSubtitleParser {
  static Future<QLSubtitleTrack?> parseNetwork(String url, int offsetMs) async {
    try {
      // 🚀 BOILERPLATE REMOVED: Routed strictly through OmniCloud Network Shell
      // This applies automatic retries, auth tokens, and traceparent tracking.
      final Uint8List bytes = await Quantum.media.getBytes(url);
      final String raw = utf8.decode(bytes);

      final List<double> timingsList = [];
      final List<String> textsList = [];
      final RegExp timeRegExp = RegExp(
          r'(\d{2}):(\d{2}):(\d{2})[,.](\d{3})\s*-->\s*(\d{2}):(\d{2}):(\d{2})[,.](\d{3})');

      final lines = raw.split('\n');
      String currentText = '';
      double currentStart = -1, currentEnd = -1;

      for (final rawLine in lines) {
        final line = rawLine.trim();
        if (line.isEmpty) {
          if (currentStart != -1 && currentText.isNotEmpty) {
            timingsList.addAll([currentStart, currentEnd]);
            textsList.add(currentText.trim());
          }
          currentStart = -1;
          currentEnd = -1;
          currentText = '';
          continue;
        }
        final match = timeRegExp.firstMatch(line);
        if (match != null) {
          currentStart = _parseMs(match, 1) + offsetMs;
          currentEnd = _parseMs(match, 5) + offsetMs;
        } else if (currentStart != -1 && int.tryParse(line) == null) {
          currentText += (currentText.isEmpty ? '' : '\n') + line;
        }
      }

      if (currentStart != -1 && currentText.isNotEmpty) {
        timingsList.addAll([currentStart, currentEnd]);
        textsList.add(currentText.trim());
      }

      if (timingsList.isEmpty) return null;
      return QLSubtitleTrack(Float64List.fromList(timingsList), textsList);
    } catch (e) {
      debugPrint('🚨 Subtitle Fetch Failed: $e');
      return null;
    }
  }

  static double _parseMs(RegExpMatch m, int offset) {
    return (int.parse(m.group(offset)!) * 3600000 +
            int.parse(m.group(offset + 1)!) * 60000 +
            int.parse(m.group(offset + 2)!) * 1000 +
            int.parse(m.group(offset + 3)!))
        .toDouble();
  }
}

// ─────────────────────────────────────────────────────────────────────── §3 ─
//  FRONTEND: THE UNIFIED CONTROLLER
// ────────────────────────────────────────────────────────────────────────────

class QLMediaPlaybackController {
  final QLMediaSource source;

  final QLSignal<Duration> position = QLSignal(Duration.zero);
  final QLSignal<Duration> duration = QLSignal(Duration.zero);
  final QLSignal<bool> isPlaying = QLSignal(false);
  final QLSignal<bool> isBuffering = QLSignal(false);
  final QLSignal<double> bufferHealth = QLSignal(0.0);
  final QLSignal<double> volume = QLSignal(1.0);
  final QLSignal<bool> isInitialized = QLSignal(false);

  final QLSignal<String?> activeSubtitle = QLSignal(null);
  QLSubtitleTrack? _subtitleTrack;

  VideoPlayerController? _videoCtrl;
  VideoPlayerController? _audioCtrl;
  Timer? _syncWatchdog;
  bool _isDisposed = false;

  QLMediaPlaybackController(this.source);

  VideoFormat? _mapFormat(QLStreamFormat f) {
    switch (f) {
      case QLStreamFormat.hls:
        return VideoFormat.hls;
      case QLStreamFormat.dash:
        return VideoFormat.dash;
      case QLStreamFormat.ss:
        return VideoFormat.ss;
      default:
        return null;
    }
  }

  Future<void> initialize({bool playOnReady = false}) async {
    if (_isDisposed || isInitialized.value) return;

    try {
      final List<Future<dynamic>> initTasks = [];

      // 🚀 PROXY ROUTING: Intercept Network Requests for Secure Playback
      String finalVideoUrl = source.videoUrl ?? '';
      String finalAudioUrl = source.audioUrl ?? '';

      // Only route through Proxy if we are NOT on Web (Local servers don't run in browsers)
      if (!kIsWeb) {
        try {
          if (finalVideoUrl.isNotEmpty && finalVideoUrl.startsWith('http')) {
            // Await the proxy URL from the Network Shell
            finalVideoUrl = await Quantum.media.getProxyPlayUrl(finalVideoUrl);
          }
          if (finalAudioUrl.isNotEmpty && finalAudioUrl.startsWith('http')) {
            finalAudioUrl = await Quantum.media.getProxyPlayUrl(finalAudioUrl);
          }
        } catch (e) {
          debugPrint('Proxy routing failed, falling back to direct URL: $e');
        }
      }

      if (finalVideoUrl.isNotEmpty) {
        _videoCtrl = VideoPlayerController.networkUrl(
          Uri.parse(finalVideoUrl),
          formatHint: _mapFormat(source.formatHint),
          httpHeaders: source.httpHeaders,
        );
        initTasks.add(_videoCtrl!.initialize());
      }

      if (source.subtitleUrl != null) {
        initTasks.add(QLSubtitleParser.parseNetwork(
                source.subtitleUrl!, source.subtitleSyncOffsetMs)
            .then((track) => _subtitleTrack = track));
      }

      await Future.wait(initTasks);
      if (_isDisposed) return;

      if (source.isSplitTrack) {
        await _videoCtrl!.setVolume(0.0);
        await _audioCtrl!.setVolume(volume.value);
        if (source.loop) {
          _videoCtrl!.setLooping(true);
          _audioCtrl!.setLooping(true);
        }
      } else {
        final ctrl = _videoCtrl ?? _audioCtrl;
        await ctrl!.setVolume(volume.value);
        if (source.loop) ctrl.setLooping(true);
      }

      (_videoCtrl ?? _audioCtrl)!.addListener(_onHardwareUpdate);
      duration.setSilent((_videoCtrl ?? _audioCtrl)!.value.duration);
      isInitialized.value = true;

      if (playOnReady || source.autoPlay) play();
    } catch (e) {
      debugPrint('🚨 QLMediaPlaybackController Init Failed: $e');
      rethrow;
    }
  }

  void _onHardwareUpdate() {
    if (_isDisposed) return;
    final primary = _videoCtrl ?? _audioCtrl;
    if (primary == null) return;
    final val = primary.value;

    if (position.value != val.position) position.setSilent(val.position);
    if (isPlaying.value != val.isPlaying) isPlaying.setSilent(val.isPlaying);
    if (isBuffering.value != val.isBuffering)
      isBuffering.setSilent(val.isBuffering);

    if (val.buffered.isNotEmpty) {
      final bufferedEnd = val.buffered.last.end.inMilliseconds;
      final total = val.duration.inMilliseconds;
      if (total > 0) bufferHealth.setSilent(bufferedEnd / total);
    }

    if (_subtitleTrack != null) {
      final String? text =
          _subtitleTrack!.getActiveText(val.position.inMilliseconds);
      if (activeSubtitle.value != text) activeSubtitle.setSilent(text);
    }

    position.forceNotify();
    isPlaying.forceNotify();
    isBuffering.forceNotify();
    bufferHealth.forceNotify();
    activeSubtitle.forceNotify();
  }

  void _startSyncWatchdog() {
    if (!source.isSplitTrack) return;
    _syncWatchdog?.cancel();
    _syncWatchdog = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_isDisposed ||
          !isPlaying.value ||
          _videoCtrl == null ||
          _audioCtrl == null) return;
      final vPos = _videoCtrl!.value.position.inMilliseconds;
      final aPos = _audioCtrl!.value.position.inMilliseconds;
      if ((vPos - aPos).abs() > 150)
        await _videoCtrl!.seekTo(_audioCtrl!.value.position);
    });
  }

  Future<void> play() async {
    if (!isInitialized.value) await initialize(playOnReady: true);
    if (source.isSplitTrack) {
      await Future.wait([_videoCtrl!.play(), _audioCtrl!.play()]);
      _startSyncWatchdog();
    } else {
      await (_videoCtrl ?? _audioCtrl)!.play();
    }
    isPlaying.value = true;
  }

  Future<void> pause() async {
    _syncWatchdog?.cancel();
    if (source.isSplitTrack) {
      await Future.wait([_videoCtrl!.pause(), _audioCtrl!.pause()]);
    } else {
      await (_videoCtrl ?? _audioCtrl)?.pause();
    }
    isPlaying.value = false;
  }

  Future<void> seek(Duration time) async {
    if (source.isSplitTrack) {
      await Future.wait([_videoCtrl!.seekTo(time), _audioCtrl!.seekTo(time)]);
    } else {
      await (_videoCtrl ?? _audioCtrl)?.seekTo(time);
    }
  }

  void setVolume(double v) {
    volume.value = v;
    (source.isSplitTrack ? _audioCtrl : (_videoCtrl ?? _audioCtrl))
        ?.setVolume(v);
  }

  void dispose() {
    _isDisposed = true;
    _syncWatchdog?.cancel();
    _videoCtrl?.dispose();
    _audioCtrl?.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────── §4 ─
//  FRONTEND: TIKTOK FEED ORCHESTRATOR
// ────────────────────────────────────────────────────────────────────────────

class QuantumMediaOrchestrator {
  final QLMediaPolicy policy;
  final List<QLMediaSource> playlist;
  final Map<int, QLMediaPlaybackController> _activeControllers = {};
  int _currentIndex = 0;

  QuantumMediaOrchestrator({required this.playlist, QLMediaPolicy? policy})
      : policy = policy ?? QLMediaPolicy.feed();

  QLMediaPlaybackController? getController(int index) =>
      _activeControllers[index];

  void onIndexChanged(int newIndex) {
    _currentIndex = newIndex;

    for (final entry in _activeControllers.entries) {
      if (entry.key != _currentIndex) {
        entry.value.pause();
        entry.value.seek(Duration.zero);
      }
    }

    _activeControllers[_currentIndex]?.play();
    _runGarbageCollectionAndPrefetch();
  }

  void _runGarbageCollectionAndPrefetch() {
    final int minKeepAlive =
        math.max(0, _currentIndex - policy.keepAliveBehind);
    final int maxPreload =
        math.min(playlist.length - 1, _currentIndex + policy.preloadAhead);

    final List<int> toKill = _activeControllers.keys
        .where((k) => k < minKeepAlive || k > maxPreload)
        .toList();
    for (final index in toKill) _activeControllers.remove(index)?.dispose();

    // 🚀 TIKTOK PRE-BUFFERING: Initialize controllers ahead of time
    final List<String> upcomingUrls = [];
    for (int i = minKeepAlive; i <= maxPreload; i++) {
      if (playlist[i].videoUrl != null) upcomingUrls.add(playlist[i].videoUrl!);
      if (!_activeControllers.containsKey(i)) {
        final ctrl = QLMediaPlaybackController(playlist[i]);
        _activeControllers[i] = ctrl;
        ctrl.initialize(); // This natively fetches the first chunk via the Proxy!
      }
    }

    // 🚀 OMEGA CACHE WARMUP (Network Range Trick)
    // For upcoming videos further down the feed, we fetch the first 1MB (1048576 bytes)
    // directly through Quantum.media to warm up the caching layer instantly.
    if (!kIsWeb) {
      for (final url in upcomingUrls) {
        // Fire-and-forget background fetch for the first megabyte
        Quantum.media.getBytes(url, headers: {
          'Range': 'bytes=0-1048576'
        }).catchError((_) => Uint8List(0));
      }
    }
  }

  void dispose() {
    for (final ctrl in _activeControllers.values) ctrl.dispose();
    _activeControllers.clear();
  }
}

// ─────────────────────────────────────────────────────────────────────── §5 ─
//  FRONTEND: LIFECYCLE WRAPPERS & SURFACES
// ────────────────────────────────────────────────────────────────────────────

class QLVideoLifecycleWrapper extends StatefulWidget {
  final QLMediaSource source;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorFallback;
  final bool showSubtitles;
  final double width;
  final double height;

  const QLVideoLifecycleWrapper({
    super.key,
    required this.source,
    required this.fit,
    this.placeholder,
    this.errorFallback,
    required this.showSubtitles,
    required this.width,
    required this.height,
  });

  @override
  State<QLVideoLifecycleWrapper> createState() =>
      _QLVideoLifecycleWrapperState();
}

class _QLVideoLifecycleWrapperState extends State<QLVideoLifecycleWrapper> {
  late final QLMediaPlaybackController _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = QLMediaPlaybackController(widget.source);
    _initializeSafe();
  }

  Future<void> _initializeSafe() async {
    try {
      await _controller.initialize(playOnReady: widget.source.autoPlay);
    } catch (e) {
      if (mounted) {
        setState(() => _hasError = true);
        QuantumTelemetry.instance.record(QLType.anomaly, 'video_stream_failure',
            context: widget.source.videoUrl);
      }
    }
  }

  @override
  void didUpdateWidget(covariant QLVideoLifecycleWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source.videoUrl != widget.source.videoUrl) {
      _controller.dispose();
      _hasError = false;
      _initializeSafe();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.errorFallback ??
          Container(
            width: widget.width > 0 ? widget.width : double.infinity,
            height: widget.height > 0 ? widget.height : double.infinity,
            color: Colors.black87,
            child: const Center(
                child: Icon(Icons.broken_image_rounded,
                    color: Colors.white54, size: 32)),
          );
    }

    Widget videoSurface = QLVideoSurface(
      controller: _controller,
      fit: widget.fit,
      placeholder: widget.placeholder,
    );

    if (widget.showSubtitles && widget.source.subtitleUrl != null) {
      videoSurface = Stack(
        fit: StackFit.expand,
        children: [
          videoSurface,
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: QLSubtitleOverlay(controller: _controller),
            ),
          )
        ],
      );
    }

    if (widget.width > 0 || widget.height > 0) {
      return SizedBox(
        width: widget.width > 0 ? widget.width : null,
        height: widget.height > 0 ? widget.height : null,
        child: videoSurface,
      );
    }

    return videoSurface;
  }
}

class QLVideoSurface extends StatelessWidget {
  final QLMediaPlaybackController controller;
  final BoxFit fit;
  final Widget? placeholder;

  const QLVideoSurface(
      {super.key,
      required this.controller,
      this.fit = BoxFit.cover,
      this.placeholder});

  @override
  Widget build(BuildContext context) {
    if (controller.source.isAudioOnly)
      return placeholder ?? const SizedBox.shrink();

    return AnimatedBuilder(
      animation: controller.isInitialized,
      builder: (context, _) {
        if (!controller.isInitialized.value)
          return placeholder ?? const ColoredBox(color: Colors.black);
        final videoCtrl = controller._videoCtrl;
        if (videoCtrl == null) return const SizedBox.shrink();

        return FittedBox(
          fit: fit,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: videoCtrl.value.size.width,
            height: videoCtrl.value.size.height,
            child: VideoPlayer(videoCtrl),
          ),
        );
      },
    );
  }
}

class QLSubtitleOverlay extends StatelessWidget {
  final QLMediaPlaybackController controller;
  const QLSubtitleOverlay({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller.activeSubtitle,
      builder: (context, _) {
        final text = controller.activeSubtitle.value;
        if (text == null || text.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8)),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2)
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────── §6 ─
//  SDUI COMPILER INTEGRATION
// ────────────────────────────────────────────────────────────────────────────

void registerQuantumMediaComponents(QuantumVM vm) {
  vm.define('q_cinema', (ctx) {
    final source = QLMediaSource(
      id: ctx.string('id'),
      videoUrl: ctx.string('videoUrl'),
      audioUrl: ctx.string('audioUrl').isEmpty ? null : ctx.string('audioUrl'),
      subtitleUrl:
          ctx.string('subtitleUrl').isEmpty ? null : ctx.string('subtitleUrl'),
      subtitleSyncOffsetMs: ctx.integer('subtitleOffsetMs', fallback: 0),
      formatHint: ctx.enumValue('format', QLStreamFormat.values,
          fallback: QLStreamFormat.auto),
      autoPlay: ctx.boolean('autoPlay', fallback: true),
    );

    return QLVideoLifecycleWrapper(
      source: source,
      fit: ctx.string('fit') == 'contain' ? BoxFit.contain : BoxFit.cover,
      placeholder: ctx.slot('placeholder'),
      errorFallback: ctx.slot('error'),
      showSubtitles: ctx.boolean('showSubtitles', fallback: true),
      width: ctx.number('width', fallback: -1),
      height: ctx.number('height', fallback: -1),
    );
  });

  vm.define('q_feed', (ctx) {
    final List<dynamic> rawList = ctx.list('playlist');
    final List<QLMediaSource> playlist = rawList
        .map((m) => QLMediaSource(
              id: m['id'].toString(),
              videoUrl: m['videoUrl'],
            ))
        .toList();

    final orchestrator = QuantumMediaOrchestrator(playlist: playlist);
    orchestrator.onIndexChanged(0);

    return _QLFeedDisposer(
      orchestrator: orchestrator,
      child: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: playlist.length,
        onPageChanged: orchestrator.onIndexChanged,
        itemBuilder: (context, index) {
          final ctrl = orchestrator.getController(index);
          if (ctrl == null) return const ColoredBox(color: Colors.black);

          return Stack(
            fit: StackFit.expand,
            children: [
              QLVideoSurface(controller: ctrl, fit: BoxFit.cover),
              Positioned.fill(
                  child: ctx.slot('overlay') ?? const SizedBox.shrink()),
            ],
          );
        },
      ),
    );
  });
}

class _QLFeedDisposer extends StatefulWidget {
  final QuantumMediaOrchestrator orchestrator;
  final Widget child;
  const _QLFeedDisposer({required this.orchestrator, required this.child});
  @override
  State<_QLFeedDisposer> createState() => _QLFeedDisposerState();
}

class _QLFeedDisposerState extends State<_QLFeedDisposer> {
  @override
  void dispose() {
    widget.orchestrator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
