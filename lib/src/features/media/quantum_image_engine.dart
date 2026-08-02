/*
 * ============================================================================
 * File: quantum_image_engine.dart
 * 
 * Description:
 * The Omega CDN Optimizer & Disk Cache Bridge for the Quantum framework. 
 * This engine handles advanced image loading, caching, resizing, and rendering 
 * using a zero-allocation GPU pipeline. It supports intelligent CDN URL rewriting, 
 * in-memory LRU caching, and native disk caching to maximize performance and minimize bandwidth.
 * 
 * Key Components:
 * - QuantumImagePipeline: Manages the LRU GPU texture cache and concurrent requests.
 * - QLImage: A smart, responsive image widget that triggers hardware painting.
 * - _QLHardwareImagePainter: Custom painter that renders images directly to the canvas.
 * - QuantumMediaEngine: Multi-tiered (L1 RAM / L2 Disk) media cache engine.
 * 
 * Dependencies/Relationships:
 * Integrates with QuantumMediaEngine for disk fallback and supports SDUI components.
 * 
 * Notes:
 * Uses ui.ImmutableBuffer and ui.instantiateImageCodecFromBuffer for zero-copy 
 * decoding, drastically reducing garbage collection overhead.
 * ============================================================================
 */
// ════════════════════════════════════════════════════════════════════════════
// QUANTUM IMAGE ENGINE v10.0 - OMEGA CDN OPTIMIZER & DISK CACHE BRIDGE
// quantum_image_engine.dart
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../foundation/quantum_primitives.dart';
import '../../foundation/quantum_async.dart';
import 'package:quantum_layout/src/runtime/api/network_shell.dart';
import 'package:crypto/crypto.dart';
// ─────────────────────────────────────────────────────────────────────── §1 ─
//  RESOLVERS & CONFIGURATION (Smart CDN Resizing)
// ────────────────────────────────────────────────────────────────────────────

abstract class QLImageResolver {
  String rewrite(String url, int width, int height, int quality);
  Future<Map<String, Uint8List>> fetchBatch(List<String> urls) async => {};
}

class QLDefaultCdnResolver extends QLImageResolver {
  final bool isLowBandwidth;
  QLDefaultCdnResolver({this.isLowBandwidth = false});

  @override
  String rewrite(String url, int width, int height, int quality) {
    if (!url.contains('cdn.') && !url.contains('res.cloudinary.com'))
      return url;

    final int finalQuality = isLowBandwidth ? (quality * 0.5).toInt() : quality;
    final int safeWidth = width > 0 ? width : 800; // Failsafe bounds

    if (url.contains('/upload/')) {
      return url.replaceFirst(
          '/upload/', '/upload/w_$safeWidth,q_$finalQuality,f_auto/');
    }
    return url;
  }
}

// ─────────────────────────────────────────────────────────────────────── §2 ─
//  THE OMEGA PIPELINE (LRU GPU Cache & Network Bridge)
// ────────────────────────────────────────────────────────────────────────────

class QuantumImagePipeline {
  static final QuantumImagePipeline instance = QuantumImagePipeline._();

  QLImageResolver resolver = QLDefaultCdnResolver();

  // LRU GPU Texture Cache
  final Map<String, ui.Image> _gpuCache = {};
  final List<String> _lruKeys = [];
  int _currentBytes = 0;
  int maxCacheBytes = 250 * 1024 * 1024; // 250 MB Soft Limit

  final Map<String, QLAsyncSignal<ui.Image>> _inFlight = {};

  QuantumImagePipeline._();

  ui.Image? getSync(String resolvedUrl) {
    if (_gpuCache.containsKey(resolvedUrl)) {
      _markUsed(resolvedUrl);
      return _gpuCache[resolvedUrl];
    }
    return null;
  }

  QLAsyncSignal<ui.Image> request({
    required String rawUrl,
    required double renderWidth,
    required double renderHeight,
    required int quality,
    required bool allowBatch,
    required bool progressiveStream,
  }) {
    final String resolvedUrl = resolver.rewrite(
        rawUrl, renderWidth.toInt(), renderHeight.toInt(), quality);

    final cached = getSync(resolvedUrl);
    if (cached != null) {
      final sig = QLAsyncSignal<ui.Image>();
      sig.data.setSilent(cached);
      return sig;
    }

    if (_inFlight.containsKey(resolvedUrl)) return _inFlight[resolvedUrl]!;

    final signal = QLAsyncSignal<ui.Image>();
    _inFlight[resolvedUrl] = signal;

    signal.load(() async {
      try {
        final Uint8List? injected = await _fetchResolverBytes(resolvedUrl);
        final Uint8List bytes = injected ?? await _fetchBytes(resolvedUrl);
        final ui.Image decodedImage = await _zeroCopyDecode(bytes);
        _cacheImage(resolvedUrl, decodedImage);
        return decodedImage;
      } finally {
        _inFlight.remove(resolvedUrl);
      }
    });

    return signal;
  }

  Future<Uint8List?> _fetchResolverBytes(String url) async {
    if (resolver is QLDefaultCdnResolver) return null;
    try {
      final Map<String, Uint8List> batch =
          await resolver.fetchBatch(<String>[url]);
      return batch[url];
    } catch (_) {
      return null;
    }
  }

  // ── 🚀 THE BACKEND BRIDGE FIX ──
  Future<Uint8List> _fetchBytes(String url) async {
    try {
      if (kIsWeb) {
        final response = await NetworkAssetBundle(Uri.parse(url)).load('');
        return response.buffer
            .asUint8List(response.offsetInBytes, response.lengthInBytes);
      } else {
        // 🚀 Native platforms route through the powerful Disk/RAM Cache Engine
        try {
          return await QuantumMediaEngine.instance.getMediaBytes(url);
        } catch (_) {
          final response = await NetworkAssetBundle(Uri.parse(url)).load('');
          return response.buffer
              .asUint8List(response.offsetInBytes, response.lengthInBytes);
        }
      }
    } catch (e) {
      debugPrint('🚨 QIE Network Failure [$url]: $e');
      return Uint8List.fromList([
        137,
        80,
        78,
        71,
        13,
        10,
        26,
        10,
        0,
        0,
        0,
        13,
        73,
        72,
        68,
        82,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        1,
        8,
        6,
        0,
        0,
        0,
        31,
        21,
        196,
        137,
        0,
        0,
        0,
        11,
        73,
        68,
        65,
        84,
        8,
        215,
        99,
        96,
        0,
        2,
        0,
        0,
        5,
        0,
        1,
        226,
        38,
        5,
        155,
        0,
        0,
        0,
        0,
        73,
        69,
        78,
        68,
        174,
        66,
        96,
        130
      ]);
    }
  }

  Future<ui.Image> _zeroCopyDecode(Uint8List bytes) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final codec = await ui.instantiateImageCodecFromBuffer(buffer);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  void _cacheImage(String key, ui.Image image) {
    final int bytes = image.width * image.height * 4;
    _currentBytes += bytes;
    _gpuCache[key] = image;
    _lruKeys.add(key);
    _evictIfNeeded();
  }

  void _markUsed(String key) {
    _lruKeys.remove(key);
    _lruKeys.add(key);
  }

  void _evictIfNeeded() {
    while (_currentBytes > maxCacheBytes && _lruKeys.isNotEmpty) {
      final oldestKey = _lruKeys.removeAt(0);
      final oldImage = _gpuCache.remove(oldestKey);
      if (oldImage != null) {
        _currentBytes -= (oldImage.width * oldImage.height * 4);
        oldImage.dispose();
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────── §3 ─
//  THE SMART RESPONSIVE WIDGET (Zero Rebuilds, Hardware Paint)
// ────────────────────────────────────────────────────────────────────────────

class QLImage extends StatefulWidget {
  final String src;
  final String? placeholderBase64;
  final BoxFit fit;
  final int quality;
  final bool allowBatch;
  final bool progressive;
  final double blurIntensity;

  const QLImage({
    super.key,
    required this.src,
    this.placeholderBase64,
    this.fit = BoxFit.cover,
    this.quality = 85,
    this.allowBatch = true,
    this.progressive = false,
    this.blurIntensity = 20.0,
  });

  @override
  State<QLImage> createState() => _QLImageState();
}

class _QLImageState extends State<QLImage> with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  QLAsyncSignal<ui.Image>? _signal;

  ui.Image? _placeholderImage;
  bool _isHighResLoaded = false;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _decodePlaceholder();
  }

  void _decodePlaceholder() async {
    if (widget.placeholderBase64 == null) return;
    try {
      final bytes = base64Decode(widget.placeholderBase64!);
      _placeholderImage =
          await QuantumImagePipeline.instance._zeroCopyDecode(bytes);
      if (mounted && !_isHighResLoaded) setState(() {});
    } catch (_) {}
  }

  void _requestImage(double width, double height) {
    if (_signal != null) return;

    final dpr = View.of(context).devicePixelRatio;

    _signal = QuantumImagePipeline.instance.request(
      rawUrl: widget.src,
      renderWidth: width * dpr,
      renderHeight: height * dpr,
      quality: widget.quality,
      allowBatch: widget.allowBatch,
      progressiveStream: widget.progressive,
    );

    _signal!.data.addListener(_onImageUpdate);
  }

  void _onImageUpdate() {
    if (_signal?.data.value != null && mounted) {
      setState(() => _isHighResLoaded = true);
      _fadeCtrl.forward();
    }
  }

  @override
  void dispose() {
    _signal?.data.removeListener(_onImageUpdate);
    _placeholderImage?.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 THE MAGIC: LayoutBuilder gets the EXACT size of the box on the screen.
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = QLSafe.finite(constraints.maxWidth, 500.0);
        final h = QLSafe.finite(constraints.maxHeight, 500.0);

        _requestImage(w, h);

        return AnimatedBuilder(
          animation: Listenable.merge([_signal?.data, _fadeCtrl]),
          builder: (context, _) {
            final highRes = _signal?.data.value;

            return CustomPaint(
              size: Size(w, h),
              painter: _QLHardwareImagePainter(
                placeholder: _placeholderImage,
                highRes: highRes,
                fit: widget.fit,
                crossfadeT: _fadeCtrl.value,
                blurSigma: widget.blurIntensity * (1.0 - _fadeCtrl.value),
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────── §4 ─
//  ZERO-ALLOCATION GPU CANVAS PAINTER
// ────────────────────────────────────────────────────────────────────────────

class _QLHardwareImagePainter extends CustomPainter {
  final ui.Image? placeholder;
  final ui.Image? highRes;
  final BoxFit fit;
  final double crossfadeT;
  final double blurSigma;

  _QLHardwareImagePainter({
    this.placeholder,
    this.highRes,
    required this.fit,
    required this.crossfadeT,
    required this.blurSigma,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (placeholder == null && highRes == null) return;

    final Rect dstRect = Offset.zero & size;

    if (placeholder != null && crossfadeT < 1.0) {
      final Paint paint = Paint()
        ..color = Color.fromRGBO(0, 0, 0, 1.0 - crossfadeT);
      if (blurSigma > 0) {
        paint.imageFilter =
            ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma);
      }
      _paintImageNative(canvas, placeholder!, dstRect, paint);
    }

    if (highRes != null && crossfadeT > 0.0) {
      final Paint paint = Paint()..color = Color.fromRGBO(0, 0, 0, crossfadeT);
      _paintImageNative(canvas, highRes!, dstRect, paint);
    }
  }

  void _paintImageNative(
      Canvas canvas, ui.Image image, Rect dstRect, Paint paint) {
    final Size imageSize =
        Size(image.width.toDouble(), image.height.toDouble());
    final FittedSizes sizes = applyBoxFit(fit, imageSize, dstRect.size);

    final Rect srcRect =
        Alignment.center.inscribe(sizes.source, Offset.zero & imageSize);
    final Rect drawRect = Alignment.center.inscribe(sizes.destination, dstRect);

    canvas.drawImageRect(image, srcRect, drawRect, paint);
  }

  @override
  bool shouldRepaint(_QLHardwareImagePainter old) =>
      old.highRes != highRes ||
      old.crossfadeT != crossfadeT ||
      old.placeholder != placeholder;
}

// ───────────────────────────────────────────────────────────────────────
//  NATIVE DISK & RAM MEDIA CACHE ENGINE
// ────────────────────────────────────────────────────────────────────────────

// ───────────────────────────────────────────────────────────────────────
//  NATIVE DISK & RAM MEDIA CACHE ENGINE (INTEGRATED WITH OMNICLOUD CORE)
// ────────────────────────────────────────────────────────────────────────────

class QuantumMediaEngine {
  static final QuantumMediaEngine instance = QuantumMediaEngine._();

  // Level 1: Fast RAM Cache for instant zero-frame re-renders
  final Map<String, Uint8List> _ramCache = {};

  QuantumMediaEngine._();

  Future<Uint8List> getMediaBytes(String url) async {
    // 1. Instant Return from L1 Cache
    if (_ramCache.containsKey(url)) {
      return _ramCache[url]!;
    }

    // 2. Web Fallback (dart:io filesystem isn't available on Web)
    if (kIsWeb) {
      final bytes =
          await Quantum.media.getBytes(url); // Routes through network.dart
      _ramCache[url] = bytes;
      return bytes;
    }

    // 3. L2 Native Disk Cache (Zero 3rd-party dependency, uses crypto & dart:io)
    // Hashing URL ensures valid filenames regardless of query parameters
    final String hash = sha256.convert(utf8.encode(url)).toString();
    final io.Directory tempDir = io.Directory.systemTemp;
    final io.File cacheFile = io.File('${tempDir.path}/q_media_$hash.bin');

    if (await cacheFile.exists()) {
      final bytes = await cacheFile.readAsBytes();
      _ramCache[url] = bytes; // Promote to L1
      return bytes;
    }

    // 4. 🚀 THE REAL NETWORK FETCH
    // Routed strictly through OmniCloud/Quantum ApiClient.
    // This applies TraceparentPolicy, RateLimiterPolicy, and HmacSigning automatically!
    final Uint8List bytes = await Quantum.media.getBytes(url);

    // 5. Fire-and-Forget Disk Write
    // Done asynchronously so we don't block the UI thread returning the image to the canvas
    cacheFile.writeAsBytes(bytes, flush: true).catchError((_) {
      // Silently ignore disk write limits (e.g. storage full) to prevent app crashes
    });

    // 6. Promote to L1 & Return to Pipeline
    _ramCache[url] = bytes;
    return bytes;
  }
}
